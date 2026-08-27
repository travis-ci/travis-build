require 'faraday'
require 'base64'
require 'digest'
require 'socket'
require 'time'
require 'core_ext/hash/deep_merge'
require 'core_ext/hash/deep_symbolize_keys'
require 'travis/github_apps'
require 'travis/build/data/ssh_key'

# actually, the worker payload can be cleaned up a lot ...

module Travis
  module Build
    class Data
      DEFAULTS = { }

      # Diagnostic (GitHub ticket 4655118). The two REST endpoints GitHub asked us to hit
      # with the freshly-minted installation token from BOTH the minting service and the
      # build worker, so they can tell whether the credential is usable at issuance, after
      # the worker handoff, or only when it reaches git. `%{slug}` is the allowlisted repo.
      TOKEN_REST_PROBE_PATHS = [
        'installation/repositories',
        'repos/%{slug}'
      ].freeze

      # Diagnostic (GitHub ticket 4655118). The git smart-HTTP ref-advertisement endpoint --
      # the FIRST request `git clone` makes and exactly where the intermittent "Invalid username
      # or token" 401 lands. Probing this from the minter with git's own Basic-auth form tells us
      # whether a token that REST accepts is ALSO accepted by the git auth surface at issuance,
      # or only fails later at the worker's clone. `%{slug}` is the allowlisted repo.
      GIT_UPLOAD_PACK_PROBE_PATH = '%{slug}.git/info/refs?service=git-upload-pack'.freeze

      DEFAULT_CACHES = {
        bundler:      false,
        cocoapods:    false,
        composer:     false,
        ccache:       false,
        pip:          false,
        npm:          true
      }

      attr_reader :data, :language_default_p

      def initialize(data, defaults = {})
        data = data.deep_symbolize_keys
        defaults = defaults.deep_symbolize_keys
        @language_default_p = data[:language_default_p]
        @data = DEFAULTS.deep_merge(defaults.deep_merge(data))
      end

      def [](key)
        data[key]
      end

      def key?(key)
        data.key?(key)
      end

      def language
        config[:language]
      end

      def group
        config[:group]
      end

      def dist
        config[:dist]
      end

      def urls
        data[:urls] || {}
      end

      def config
        data[:config]
      end

      def hosts
        data[:hosts] || {}
      end

      def cache_options
        data[:cache_settings] || data[:cache_options] || {}
      end

      def workspace
        data[:workspace] || cache_options
      end

      def cache(input = config[:cache])
        case input
        when Hash           then input
        when Array          then input.map { |e| cache(e) }.inject(:merge)
        when String, Symbol then { input.to_sym => true }
        when nil            then {} # for ruby 1.9
        when false          then Hash[DEFAULT_CACHES.each_key.with_object(false).to_a]
        else input.to_h
        end
      end

      def cache?(type, default = DEFAULT_CACHES[type])
        type &&= type.to_sym
        !!cache.fetch(type) { default }
      end

      def env_vars
        data[:env_vars] || []
      end

      def vm_config
        data[:vm_config] || []
      end

      def custom_ssh_key?
        !!ssh_key&.custom?
      end

      def ssh_key?
        !!ssh_key
      end

      def ssh_key
        @ssh_key ||= if ssh_key = data[:ssh_key]
          SshKey.new(ssh_key[:value], ssh_key[:source], ssh_key[:encoded], ssh_key[:public_key])
        elsif data[:config] && source_key = data[:config][:source_key]
          SshKey.new(source_key, nil, true, nil)
        end
      end

      def pull_request?
        !!pull_request
      end

      def pull_request
        job[:pull_request]
      end

      def secure_env?
        !!job[:secure_env_enabled]
      end

      def secure_env_removed?
        !!job[:secure_env_removed]
      end

      def secrets
        Array(data[:secrets])
      end

      def vault_secrets=(v_secrets)
        data[:vault_secrets] = Array(v_secrets)
      end

      def vault_secrets
        Array(data[:vault_secrets])
      end

      def disable_sudo?
        !!data[:paranoid]
      end

      def api_url
        repository[:api_url]
      end

      def source_url
        source_ssh? ? source_ssh_url : source_https_url
      end

      def source_https?
        !source_ssh?
      end

      def source_ssh?
        return false if prefer_https?
        ((repo_private? || force_private?) && !installation?) ||
          ((repo_private? || enterprise?) && custom_ssh_key?)
      end

      def force_private?
        github? && !source_host&.include?('github.com')
      end

      def enterprise?
        ENV['TRAVIS_ENTERPRISE'] == 'true' || nil
      end

      def github?
        repository[:vcs_type] == 'GithubRepository'
      end

      def source_host
        repository[:source_host]
      end

      def source_ssh_url
        "git@#{source_host}:#{slug}.git"
      end

      def source_https_url
        "https://#{source_host}/#{slug}.git"
      end

      def slug
        repository[:slug] || raise('data.slug must not be empty')
      end

      def github_id
        repository[:vcs_id] || repository.fetch(:github_id)
      end

      def repo_private?
        repository[:private]
      end

      def default_branch
        repository[:default_branch]
      end

      def commit
        job[:commit] || ''
      end

      def branch
        job[:branch] || ''
      end

      def tag
        job[:tag]
      end

      def ref
        job[:ref]
      end

      def job
        data[:job] || {}
      end

      def build
        data[:source] || data[:build] || {} # TODO standarize the payload on :build
      end

      def repository
        data[:repository] || {}
      end

      def allowed_repositories
        data[:allowed_repositories] || [github_id]
      end

      def token
        # CHANGE FOR DEPLOY
        #
        # Memoized so the credential is minted exactly ONCE per build. #installation_token
        # builds its GithubApps client with an empty config, so the gem's redis cache is
        # inactive and every call otherwise mints a brand-new token over HTTP. That is what
        # made the diagnostic in lib/travis/vcs/git/netrc.rb (which also calls #token) mint a
        # second token ~200ms after the one actually written to the netrc -- the double-mint
        # GitHub traced. `defined?` (not `||=`) so a nil/failed mint is cached too and never
        # retried in a tight loop. Returning the same object also makes the mint-time and
        # netrc-write fingerprints comparable (see #log_token_fingerprint).
        return @token if defined?(@token)
        @token = installation? ? installation_token : data[:oauth_token]
        log_token_fingerprint('mint', @token)
        # GitHub ticket 4655118: from the service that minted it, immediately exercise the
        # token against REST so we can compare with the same probe on the worker (clone.rb)
        # and with the git edge. Allowlisted slugs only (empty by default -> no-op).
        probe_token_rest('mint') if (installation? rescue false) && trace_token_probe?
        # Same token, git's own auth surface (Basic base64("travis-ci:<token>")) against the
        # smart-HTTP ref advertisement -- the request git actually makes. Compared with the REST
        # probe above and the worker clone, this localizes whether the 401 exists at issuance.
        probe_token_git_surface('mint') if (installation? rescue false) && trace_token_probe?
        @token
      end

      def debug_options
        job[:debug_options] || {}
      end

      def prefer_https?
        data[:prefer_https]
      end

      def keep_netrc?
        data.key?(:keep_netrc) ? data[:keep_netrc] : true
      end

      def installation?
        !!installation_id
      end

      def installation_id
        repository[:installation_id]
      end

      def installation_token
        GithubApps.new(installation_id, {}, allowed_repositories).access_token
      rescue RuntimeError => e
        log_installation_token_failure(e)
        if e.message =~ /Failed to obtain token from GitHub/
          raise Travis::Build::GithubAppsTokenFetchError.new
        end

        # Any other mint failure falls through to a nil token here. The git netrc
        # (lib/travis/vcs/git/netrc.rb) then writes an empty password, and the clone fails with
        # the opaque "remote: Invalid username or token. Password authentication is not supported
        # for Git operations." We log the real cause above so the failure is diagnosable from
        # travis-build logs instead of being silently swallowed.
        nil
      end

      # Emit a structured, greppable record when an installation-token mint fails, so support/eng
      # can tie an opaque clone failure back to the customer, repo, installation, and root error.
      # Diagnostics must never interfere with token handling, hence the outer rescue.
      def log_installation_token_failure(error)
        details = {
          event:                'installation_token_fetch_failed',
          repo_slug:            (slug rescue nil),
          github_id:            (github_id rescue nil),
          installation_id:      installation_id,
          job_id:               (job[:id] rescue nil),
          allowed_repositories: allowed_repositories,
          error_class:          error.class.name,
          error_message:        error.message.to_s[0, 500],
          # true  => raises GithubAppsTokenFetchError (build fails at compilation with a clear error)
          # false => returns a nil token => clone fails later with "Invalid username or token"
          will_raise:           !(error.message =~ /Failed to obtain token from GitHub/).nil?
        }
        summary = details.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')
        Travis::Build.logger.error(
          "[installation_token] mint failed for GitHub App installation; " \
          "clone will fail with 'Invalid username or token' unless it succeeds on retry -- #{summary}"
        )
      rescue => logging_error
        # Never let diagnostics break the build path.
        Travis::Build.logger.warn(
          "[installation_token] failed to log mint failure: #{logging_error.class}: #{logging_error.message}"
        ) rescue nil
      end

      # Diagnostic only. Records a NON-reversible fingerprint (byte length + short SHA-256
      # prefix) of the credential right after it is minted, so it can be compared with the
      # fingerprint taken immediately before the netrc/Basic-auth header is built
      # (lib/travis/vcs/git/netrc.rb) and with the worker-side check in git/clone.rb.
      # Matching fingerprints prove the exact token we minted is the one handed to git; a
      # mismatch would prove in-process corruption -- exactly what GitHub asked us to confirm.
      # The token value itself is NEVER logged. Server-side (travis-build logs) only, and
      # wrapped so diagnostics can never break the build.
      def log_token_fingerprint(stage, value)
        return unless defined?(Travis::Build) && Travis::Build.respond_to?(:logger)

        secret  = value.to_s
        present = !secret.strip.empty?
        details = {
          event:           'git_token_fingerprint',
          stage:           stage,
          repo_slug:       (slug rescue nil),
          installation_id: ((installation_id rescue nil) if (installation? rescue false)),
          job_id:          (job[:id] rescue nil),
          credential_present: present,
          credential_length:  secret.length,
          credential_sha256:  (present ? Digest::SHA256.hexdigest(secret)[0, 16] : nil)
        }
        summary = details.reject { |_, v| v.nil? }.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')
        Travis::Build.logger.info("[git_token_fingerprint] #{summary}")
      rescue => e
        Travis::Build.logger.warn("[git_token_fingerprint] failed: #{e.class}: #{e.message}") rescue nil
      end

      # Reuses the SAME allowlist gate as the worker-side git tracing (clone.rb): only repos
      # in TRACE_GIT_COMMANDS_SLUGS (empty by default) are probed, so this never runs for a
      # customer build and adds no GitHub API calls to the hot path. Wrapped so a config
      # surprise can never break the mint.
      def trace_token_probe?
        return false unless defined?(Travis::Build) && Travis::Build.respond_to?(:config)
        slugs = Travis::Build.config.trace_git_commands_slugs.output_safe.split(',')
        slugs.include?(slug)
      rescue StandardError
        false
      end

      # Diagnostic only (GitHub ticket 4655118). From the minting service, in-process, hit the
      # two REST endpoints GitHub specified with the token we just minted and record — per
      # request — HTTP status, X-GitHub-Request-Id, GitHub's Date response header (their common
      # clock), a local UTC timestamp, a monotonic reading (drift-immune within this process),
      # this service's identifier, and the same non-reversible length + SHA-256 fingerprint we
      # log elsewhere. The token itself and the Authorization header are NEVER logged. Compared
      # with the worker-side probe (clone.rb) and the git edge, this tells GitHub whether the
      # credential is already unusable at issuance. Server-side logs only; wrapped so diagnostics
      # can never break the build.
      def probe_token_rest(stage)
        return unless defined?(Travis::Build) && Travis::Build.respond_to?(:logger)

        secret = token.to_s
        return if secret.strip.empty?

        fingerprint = Digest::SHA256.hexdigest(secret)[0, 16]
        endpoint    = ENV['GITHUB_API_ENDPOINT'] || 'https://api.github.com'
        service_id  = (Socket.gethostname rescue nil)
        conn = Faraday.new(url: endpoint) do |f|
          f.options.timeout      = 5
          f.options.open_timeout = 5
          f.adapter Faraday.default_adapter
        end

        TOKEN_REST_PROBE_PATHS.each do |template|
          path      = format(template, slug: slug)
          monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            response = conn.get(path) do |req|
              req.headers['Authorization'] = "token #{secret}" # NEVER logged
              req.headers['Accept']        = 'application/vnd.github+json'
              req.headers['User-Agent']    = 'travis-build-token-probe'
            end
            log_token_rest_probe(
              stage:             stage,
              path:              path,
              http_status:       response.status,
              github_request_id: response.headers['x-github-request-id'],
              github_date:       response.headers['date'],
              service_id:        service_id,
              monotonic_s:       monotonic.round(3),
              length:            secret.length,
              fingerprint:       fingerprint
            )
          rescue StandardError => e
            Travis::Build.logger.warn(
              "[git_token_rest_probe] request failed path=#{path.inspect} #{e.class}: #{e.message}"
            ) rescue nil
          end
        end
      rescue StandardError => e
        Travis::Build.logger.warn("[git_token_rest_probe] setup failed: #{e.class}: #{e.message}") rescue nil
      end

      def log_token_rest_probe(fields)
        details = {
          event:             'git_token_rest_probe',
          location:          'minter',
          stage:             fields[:stage],
          path:              fields[:path],
          http_status:       fields[:http_status],
          github_request_id: fields[:github_request_id],
          github_date:       fields[:github_date],
          local_utc:         (Time.now.utc.iso8601(3) rescue nil),
          monotonic_s:       fields[:monotonic_s],
          service_id:        fields[:service_id],
          repo_slug:         (slug rescue nil),
          installation_id:   ((installation_id rescue nil) if (installation? rescue false)),
          job_id:            (job[:id] rescue nil),
          credential_length: fields[:length],
          credential_sha256: fields[:fingerprint]
        }
        summary = details.reject { |_, v| v.nil? }.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')
        Travis::Build.logger.info("[git_token_rest_probe] #{summary}")
      end

      # Diagnostic only (GitHub ticket 4655118). The git-surface counterpart to
      # #probe_token_rest: from the minting service, in-process, hit the git smart-HTTP ref
      # advertisement (info/refs?service=git-upload-pack) -- the exact first request git makes,
      # and where the intermittent "Invalid username or token" 401 occurs -- using git's OWN
      # credential form, Basic base64("travis-ci:<token>"), instead of REST's "token <token>".
      # If the token REST-probes 200 but git-probes 401 HERE, it is already unusable for git at
      # issuance (a re-mint before handoff could help); if it git-probes 200 here but the
      # worker's clone still 401s, the failure is downstream (later / other worker / other edge).
      # Records HTTP status, X-GitHub-Request-Id, GitHub's Date header, a local UTC timestamp, a
      # monotonic reading, this service's id, and the same non-reversible length + SHA-256
      # fingerprint. The token and the Authorization header are NEVER logged. Server-side logs
      # only; wrapped so diagnostics can never break the mint.
      def probe_token_git_surface(stage)
        return unless defined?(Travis::Build) && Travis::Build.respond_to?(:logger)

        secret = token.to_s
        return if secret.strip.empty?
        host = source_host.to_s
        return if host.empty?

        fingerprint = Digest::SHA256.hexdigest(secret)[0, 16]
        service_id  = (Socket.gethostname rescue nil)
        path        = format(GIT_UPLOAD_PACK_PROBE_PATH, slug: slug)
        # git presents installation creds as HTTP Basic (login travis-ci / password <token>) --
        # NOT the REST "Authorization: token" form. This surface difference is the whole point.
        authorization = "Basic #{Base64.strict_encode64("travis-ci:#{secret}")}" # NEVER logged
        conn = Faraday.new(url: "https://#{host}") do |f|
          f.options.timeout      = 5
          f.options.open_timeout = 5
          f.adapter Faraday.default_adapter
        end

        monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        begin
          response = conn.get(path) do |req|
            req.headers['Authorization'] = authorization # NEVER logged
            req.headers['User-Agent']    = 'git/2.39.0'
            req.headers['Accept']        = '*/*'
          end
          log_token_git_probe(
            stage:             stage,
            path:              path,
            http_status:       response.status,
            github_request_id: response.headers['x-github-request-id'],
            github_date:       response.headers['date'],
            service_id:        service_id,
            monotonic_s:       monotonic.round(3),
            length:            secret.length,
            fingerprint:       fingerprint
          )
          # SENSITIVE / TEMPORARY (GitHub ticket 4655118): log the raw token so GitHub can inspect
          # the exact bytes they rejected. Runs under this method's existing gatekeeper-only gate
          # (trace_token_probe? at the call site). SERVER-SIDE pod log only (this is
          # Travis::Build.logger, NOT the customer-visible job log). Correlate this line to a later
          # worker git 401 by credential_sha256. Remove this call (and the method) once GitHub has it.
          capture_raw_token_for_github(stage, response.status, fingerprint, secret)
        rescue StandardError => e
          Travis::Build.logger.warn(
            "[git_token_git_probe] request failed path=#{path.inspect} #{e.class}: #{e.message}"
          ) rescue nil
        end
      rescue StandardError => e
        Travis::Build.logger.warn("[git_token_git_probe] setup failed: #{e.class}: #{e.message}") rescue nil
      end

      # SENSITIVE / TEMPORARY (GitHub ticket 4655118). Emits the RAW installation token to the
      # server-side pod log, keyed to the same credential_sha256 the other probes log, so GitHub
      # can compare the exact bytes against their debug logs. Only reached via the git-surface
      # probe, which is gatekeeper-only (trace_token_probe?) -> never runs for a customer build.
      # The token is scoped to the allowlisted repo (contents:read), lives ~1h, and is expired
      # before it reaches GitHub. Distinct marker so the line can be located (and scrubbed)
      # afterwards. Wrapped so it can never break the mint.
      def capture_raw_token_for_github(stage, http_status, fingerprint, secret)
        return unless defined?(Travis::Build) && Travis::Build.respond_to?(:logger)
        return if secret.to_s.empty?
        details = {
          event:             'github_raw_token_capture',
          note:              'SENSITIVE-expires-1h-scoped-to-repo-for-ticket-4655118',
          stage:             stage,
          minter_git_status: http_status,
          repo_slug:         (slug rescue nil),
          installation_id:   ((installation_id rescue nil) if (installation? rescue false)),
          job_id:            (job[:id] rescue nil),
          local_utc:         (Time.now.utc.iso8601(3) rescue nil),
          credential_length: secret.length,
          credential_sha256: fingerprint,
          raw_token:         secret
        }
        summary = details.reject { |_, v| v.nil? }.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')
        Travis::Build.logger.warn("[github_raw_token_capture] #{summary}")
      rescue StandardError => e
        Travis::Build.logger.warn("[github_raw_token_capture] failed: #{e.class}: #{e.message}") rescue nil
      end

      def log_token_git_probe(fields)
        details = {
          event:             'git_token_git_probe',
          location:          'minter',
          surface:           'git',
          stage:             fields[:stage],
          path:              fields[:path],
          http_status:       fields[:http_status],
          github_request_id: fields[:github_request_id],
          github_date:       fields[:github_date],
          local_utc:         (Time.now.utc.iso8601(3) rescue nil),
          monotonic_s:       fields[:monotonic_s],
          service_id:        fields[:service_id],
          repo_slug:         (slug rescue nil),
          installation_id:   ((installation_id rescue nil) if (installation? rescue false)),
          job_id:            (job[:id] rescue nil),
          credential_length: fields[:length],
          credential_sha256: fields[:fingerprint]
        }
        summary = details.reject { |_, v| v.nil? }.map { |k, v| "#{k}=#{v.inspect}" }.join(' ')
        Travis::Build.logger.info("[git_token_git_probe] #{summary}")
      end

      def workspaces
        config[:workspaces]
      end
    end
  end
end
