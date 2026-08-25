require 'shellwords'
require 'travis/vcs/git/netrc'

module Travis
  module Vcs
    class Git < Base
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'git.checkout' do
            sh.export 'GIT_LFS_SKIP_SMUDGE', '1' if lfs_skip_smudge?
            sh.cmd 'ssh-keygen -R github.com >/dev/null 2>&1 || true', echo: false
            sh.file '~/.ssh/known_hosts', <<~EOF, append: true, echo: false
              github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
              github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
              github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
            EOF
            verify_netrc_credential if trace_git_commands?
            probe_token_rest if trace_git_commands?
            clone_or_fetch
            signal_clone_auth_401 if remint_on_clone_auth?
            sh.cd dir
            fetch_ref if fetch_ref?
            checkout
            sh.cmd "git fsck", assert: false, retry: true if trace_git_commands?
          end
          sh.newline
        end

        private
          TRACE_COMMAND_GIT_TRACE = "GIT_TRACE=true"
          TRACE_COMMAND_STRACE = "strace"
          TRACE_COMMAND_CURL = "curl"
          TRACE_COMMAND_ALL = "all"
          DEFAULT_TRACE_COMMAND = TRACE_COMMAND_GIT_TRACE

          def repo_slug
            data.repository[:slug].to_s
          end

          def owner_login
            repo_slug.split('/').first
          end

          def trace_git_commands_owners
            Travis::Build.config.trace_git_commands_owners.output_safe.split(',')
          end

          def trace_git_commands_slugs
            Travis::Build.config.trace_git_commands_slugs.output_safe.split(',')
          end

          def trace_git_commands?
            trace_git_commands_slugs.include?(repo_slug) || trace_git_commands_owners.include?(owner_login)
          end

          # Exit code build.sh uses to signal "git clone failed with an auth 401" so the worker
          # knows to re-mint a fresh installation token and retry (rather than reusing the rejected
          # one). Chosen to not collide with existing codes (0 pass, 1 fail, 2 assert-terminate,
          # 86 preamble). Keep in sync with the worker's cloneAuthRemintExitCode. Ticket 4655118.
          CLONE_AUTH_REMINT_EXIT_CODE = 89

          def clone_auth_remint_slugs
            Travis::Build.config.clone_auth_remint_slugs.output_safe.split(',')
          end

          # ALLOWLISTED REPOS ONLY (empty by default -> never fires for a customer build), and only
          # for GitHub-App installation-token repos (the only ones that can re-mint). Gated via its
          # own CLONE_AUTH_REMINT_SLUGS Vault env.
          def remint_on_clone_auth?
            return false unless (data.installation? rescue false)
            clone_auth_remint_slugs.include?(repo_slug)
          end

          # Emitted right after the clone attempt (allowlisted repos only). If the clone did NOT
          # produce a checkout (#{dir}/.git missing) we re-test git's own auth surface once -- the
          # smart-HTTP ref advertisement with git's Basic auth form -- and ONLY on a definitive
          # HTTP 401 do we `travis_terminate 89`. That code tells the worker to re-mint a fresh
          # installation token and re-run (bounded retry). Checking the HTTP status (not git's
          # localized "Invalid username or token" text) keeps this precise to auth failures and
          # skips network/other clone failures. NEVER prints the token or the Authorization header:
          # the token stays in a shell var, the Basic string is computed inline, and sh.raw does not
          # echo the command text to the log (same mechanism the netrc write already relies on).
          def signal_clone_auth_401
            netrc = "${TRAVIS_HOME}/#{netrc_basename}"
            url = "https://#{data.source_host}/#{repo_slug}.git/info/refs?service=git-upload-pack"
            code = CLONE_AUTH_REMINT_EXIT_CODE
            sh.raw <<~BASH
              if [ ! -d #{dir}/.git ] && [ -f #{netrc} ]; then
                __car_tok=$(awk 'tolower($1)=="password"{print $2; exit}' #{netrc})
                if [ -n "$__car_tok" ]; then
                  __car_auth=$(printf 'travis-ci:%s' "$__car_tok" | base64 | tr -d '\\n')
                  __car_code=$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 15 -H "Authorization: Basic $__car_auth" -H 'User-Agent: git/2.39.0' "#{url}" 2>/dev/null)
                  if [ "$__car_code" = "401" ]; then
                    echo "[clone_auth_remint] git clone auth returned 401 for #{repo_slug}; requesting a fresh installation token (exit #{code})"
                    unset __car_tok __car_auth __car_code
                    travis_terminate #{code}
                  fi
                  unset __car_auth __car_code
                fi
                unset __car_tok
              fi
            BASH
          end

          def trace_command
            if Travis::Build.config.trace_command.output_safe == TRACE_COMMAND_ALL
              "GIT_TRACE=true GIT_FLUSH=1 GIT_TRACE_PERFORMANCE=true GIT_TRACE_PACK_ACCESS=true GIT_TRACE_PACKET=true GIT_TRACE_PACK_ACCESS=true strace"
            elsif Travis::Build.config.trace_command.output_safe == TRACE_COMMAND_CURL
              # Dump the HTTP request/response headers (incl. status + X-GitHub-Request-Id) so an
              # opaque "Invalid username or token" clone failure shows GitHub's real reason.
              # GIT_TRACE_CURL redacts the Authorization header; _NO_DATA suppresses the body.
              "GIT_TRACE_CURL=1 GIT_TRACE_CURL_NO_DATA=1"
            elsif Travis::Build.config.trace_command.output_safe == TRACE_COMMAND_STRACE
              "strace"
            else
              DEFAULT_TRACE_COMMAND
            end
          end

          def git_cmd
            trace_git_commands? ? "#{trace_command} git" : "git"
          end

          # Diagnostic, ALLOWLISTED REPOS ONLY (gated by trace_git_commands? in #apply, which
          # is empty by default -- this never emits for a customer build). Prints the byte
          # length + short SHA-256 of the credential exactly as it sits in the netrc git is
          # about to read, i.e. the bytes immediately before git builds the HTTP Basic auth
          # header. Compared with the server-side mint fingerprint (build/data.rb), this proves
          # whether the token reached the worker unchanged -- the truncation/line-wrap check
          # GitHub asked for. NEVER prints the token: only its length and a one-way hash prefix.
          # assert:false + `|| true` so it can never fail the build.
          def verify_netrc_credential
            netrc = "${TRAVIS_HOME}/#{netrc_basename}"
            cmd = "if [ -f #{netrc} ]; then " \
                  "__p=$(awk 'tolower($1)==\"password\"{print $2; exit}' #{netrc}); " \
                  "printf '[git_netrc_verify] credential length=%s sha256=%s\\n' " \
                  "\"${#__p}\" \"$(printf %s \"$__p\" | sha256sum 2>/dev/null | cut -c1-16)\"; " \
                  "unset __p; fi || true"
            sh.cmd cmd, echo: false, assert: false, timing: false
          end

          def netrc_basename
            data.config[:os].to_s.downcase == 'windows' ? '_netrc' : '.netrc'
          end

          GITHUB_API_ENDPOINT = "https://api.github.com"

          # The two REST endpoints GitHub asked us to hit (ticket 4655118) — the second scoped
          # to the repo being cloned.
          def token_rest_probe_paths
            ["/installation/repositories", "/repos/#{repo_slug}"]
          end

          # Diagnostic, ALLOWLISTED REPOS ONLY (gated by trace_git_commands? in #apply). The
          # worker counterpart to build/data.rb#probe_token_rest: immediately before git runs,
          # take the SAME token out of the netrc and exercise it against the same two REST
          # endpoints from THIS machine, capturing per request the HTTP status,
          # X-GitHub-Request-Id, GitHub's Date response header (the common clock GitHub asked
          # for), a local UTC timestamp, this worker's hostname, and the same token length +
          # short SHA-256. If REST succeeds here but the clone 401s, the divergence is git-vs-REST
          # auth at their edge; if REST fails here too, the credential died in the handoff.
          # NEVER prints the token or the Authorization header: curl dumps RESPONSE headers only
          # (-D -, no -v), the token lives only in a shell variable, and echo:false keeps the
          # command text (a $var reference, not the literal) out of the log. assert:false + `|| true`
          # so it can never fail the build.
          def probe_token_rest
            netrc = "${TRAVIS_HOME}/#{netrc_basename}"
            cmd = +""
            cmd << "if [ -f #{netrc} ]; then "
            cmd << "__tok=$(awk 'tolower($1)==\"password\"{print $2; exit}' #{netrc}); "
            cmd << "if [ -n \"$__tok\" ]; then "
            cmd << "__len=${#__tok}; "
            cmd << "__sha=$(printf %s \"$__tok\" | sha256sum 2>/dev/null | cut -c1-16); "
            token_rest_probe_paths.each do |path|
              cmd << "__hdr=$(curl -sS -o /dev/null -D - "
              cmd << "--connect-timeout 5 --max-time 10 "
              cmd << "-H \"Authorization: token $__tok\" "
              cmd << "-H 'Accept: application/vnd.github+json' "
              cmd << "-H 'User-Agent: travis-build-token-probe' "
              cmd << "#{GITHUB_API_ENDPOINT}#{path} 2>/dev/null); "
              cmd << "__status=$(printf '%s\\n' \"$__hdr\" | awk 'toupper($1) ~ /^HTTP/ {print $2; exit}'); "
              cmd << "__rid=$(printf '%s\\n' \"$__hdr\" | awk 'tolower($1)==\"x-github-request-id:\"{print $2; exit}'); "
              cmd << "__ghd=$(printf '%s\\n' \"$__hdr\" | awk 'tolower($0) ~ /^date:/ {sub(/^[^:]*: */, \"\"); print; exit}'); "
              cmd << "printf '[git_token_rest_probe] location=worker path=%s http_status=%s github_request_id=%s github_date=\\\"%s\\\" local_utc=%s worker_id=%s credential_length=%s credential_sha256=%s\\n' "
              cmd << "\"#{path}\" \"$__status\" \"$__rid\" \"$__ghd\" \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\" \"$(hostname 2>/dev/null)\" \"$__len\" \"$__sha\"; "
            end
            cmd << "fi; unset __tok __len __sha __hdr __status __rid __ghd; fi || true"
            sh.cmd cmd, echo: false, assert: false, timing: false
          end

          def git_clone
            sh.cmd "#{git_cmd} clone #{clone_args} #{data.source_url} #{dir}", assert: false, retry: true
            if vcs_pull_request?
              sh.if "$? -ne 0" do
                sh.cmd "#{git_cmd} clone #{clone_args(true)} #{data.source_url} #{dir}", assert: false, retry: true
              end
            end
          end

           def git_fetch
            sh.cmd "#{git_cmd} -C #{dir} fetch origin#{fetch_args}", assert: true, retry: true
          end

          def clone_or_fetch
            if autocrlf_key_given?
              sh.cmd "git config --global core.autocrlf #{config[:git][:autocrlf].to_s}"
            end
            sh.if "! -d #{dir}/.git" do
              if sparse_checkout
                sh.echo "Cloning with sparse checkout specified with #{sparse_checkout}", ansi: :yellow
                sh.cmd "git init #{dir}", assert: true, retry: true
                sh.cmd "git -C #{dir} config core.sparseCheckout true", assert: true, retry: true
                sh.cmd "echo #{sparse_checkout} >> #{dir}/.git/info/sparse-checkout", assert: true, retry: true
                sh.cmd "git -C #{dir} remote add origin #{data.source_url}", assert: true, retry: true
                sh.cmd "git -C #{dir} pull origin #{branch} #{pull_args}", assert: false, retry: true
                sh.cmd "cat #{dir}/#{sparse_checkout} >> #{dir}/.git/info/sparse-checkout", assert: true, retry: true
                sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
              else
                git_clone
              end
            end
            sh.else do
              git_fetch
              sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
            end
          end

          def fetch_ref
            sh.cmd "#{git_cmd} fetch origin +#{data.ref}:#{fetch_args}", assert: true, retry: true
          end

          def fetch_ref?
            !!data.ref
          end

          def checkout
            return fetch_head_alternative if vcs_pull_request?
            sh.cmd "git checkout -qf #{checkout_ref}", timing: false
          end

          def checkout_ref
            return 'FETCH_HEAD' if data.pull_request
            return tag if data.tag
            data.commit
          end

          def fetch_head_alternative
            sh.cmd "#{git_cmd} fetch -q #{data.source_url} #{pull_request_base_branch}", timing: false  #update branch to pull_request_base_branch

            if pull_request_base_slug && pull_request_head_slug != pull_request_base_slug
              sh.cmd "#{git_cmd} checkout -q FETCH_HEAD", timing: false
              sh.cmd "#{git_cmd} remote add -t #{pull_request_head_branch} upstream #{pull_request_head_url}", timing: false
              sh.cmd "#{git_cmd} fetch upstream", assert: true, retry: true
              sh.cmd "#{git_cmd} merge --squash upstream/#{pull_request_head_branch}", assert: true, retry: true
            else
              sh.cmd "#{git_cmd} fetch origin #{pull_request_head_branch}", timing: false
              sh.cmd "#{git_cmd} branch #{pull_request_head_branch} FETCH_HEAD", timing: false
              sh.cmd "#{git_cmd} checkout #{branch}", timing: false
              sh.cmd "#{git_cmd} merge #{pull_request_head_branch} -m 'Travis CI build'", timing: false
            end
          end

          def clone_args(skip_branch = false)
            branch_name = vcs_pull_request? ? pull_request_base_branch : branch
            args = depth_flag
            args << " --branch=#{tag || branch_name}" unless data.ref || skip_branch
            args << " --quiet" if quiet?
            args << " --single-branch" if skip_branch
            args
          end

          def pull_args
            args = depth_flag
            args << " --quiet" if quiet?
            args
          end

          def fetch_args
            args = " "
            args << depth_flag
            args << " --quiet" if quiet?
            args
          end

          def depth_flag
            if config[:git][:depth]
              "--depth=#{config[:git][:depth].to_s.shellescape}"
            else
              ""
            end
          end

          def autocrlf_key_given?
            config[:git].key?(:autocrlf)
          end

          def branch
            data.branch.shellescape if data.branch
          end

          def pull_request_head_branch
            data.job[:pull_request_head_branch].shellescape if data.job[:pull_request_head_branch]
          end

          def pull_request_base_branch
            data.job[:pull_request_base_ref].shellescape if data.job[:pull_request_base_ref]
          end

          def pull_request_base_slug
            data.job[:pull_request_base_slug].shellescape if data.job[:pull_request_base_slug]
          end

          def pull_request_head_slug
            data.job[:pull_request_head_slug].shellescape if data.job[:pull_request_head_slug]
          end

          def pull_request_head_url
            data.job[:pull_request_head_url].shellescape if data.job[:pull_request_head_url]
          end

          def tag
            data.tag.shellescape if data.tag
          end

          def quiet?
            config[:git][:quiet]
          end

          def lfs_skip_smudge?
            config[:git][:lfs_skip_smudge] == true
          end

          def sparse_checkout
            config[:git][:sparse_checkout]
          end

          def dir
            data.slug
          end

          def config
            data.config
          end

          def vcs_pull_request?
            data.repository[:vcs_type].to_s != '' && data.repository[:vcs_type].to_s != 'GithubRepository' && data.pull_request
          end
      end
    end
  end
end
