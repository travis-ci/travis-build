require 'shellwords'

require 'travis/build/script/shared/directory_cache/signatures/aws2_signature'
require 'travis/build/script/shared/directory_cache/signatures/aws4_signature'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Base
          MSGS = {
            config_missing: 'Worker %s config missing: %s'
          }

          VALIDATE = {
            bucket:            'bucket name',
            access_key_id:     'access key id',
            secret_access_key: 'secret access key'
          }

          CURL_FORMAT = <<-EOF
             time_namelookup:  %{time_namelookup} s
                time_connect:  %{time_connect} s
             time_appconnect:  %{time_appconnect} s
            time_pretransfer:  %{time_pretransfer} s
               time_redirect:  %{time_redirect} s
          time_starttransfer:  %{time_starttransfer} s
              speed_download:  %{speed_download} bytes/s
               url_effective:  %{url_effective}
                             ----------
                  time_total:  %{time_total} s
          EOF

          DEFAULT_AWS_SIGNATURE_VERSION = '4'

          COMMANDS_REQUIRING_SIG = %w(fetch push)

          # maximum number of directories to be 'added' to cache via casher
          # in one invocation
          ADD_DIR_MAX = 100

          KeyPair = Struct.new(:id, :secret)

          Location = Struct.new(:scheme, :region, :bucket, :path, :host, :signature_version) do
            def hostname
              case signature_version
              when '2'
                "#{bucket}.#{host}"
              else
                host
              end
            end
          end

          CASHER_URL = 'https://raw.githubusercontent.com/travis-ci/casher/%s/bin/casher'
          BIN_PATH   = '$CASHER_DIR/bin/casher'

          attr_reader :sh, :data, :slug, :start, :msgs
          attr_accessor :signer

          def initialize(sh, data, slug, start = Time.now)
            @sh = sh
            @data = data
            @slug = slug
            @start = start
            @msgs = []
          end

          def valid?
            validate
            msgs.empty?
          end

          def signature(verb, path, options)
            @signer = case data_store_options.fetch(:aws_signature_version, DEFAULT_AWS_SIGNATURE_VERSION).to_s
            when '2'
              Signatures::AWS2Signature.new(
                key: key_pair,
                http_verb: verb,
                location: location(path),
                expires: (start+ options[:expires].to_i).to_i,
                access_id_param: self.class.const_get(:ACCESS_ID_PARAM_NAME),
              )
            else
              Signatures::AWS4Signature.new(
                key: key_pair,
                http_verb: verb,
                location: location(path),
                expires: options[:expires],
                timestamp: start
              )
            end
          end

          def setup_casher
            fold 'Setting up build cache' do
              run_rvm_use
              install
              fetch
              add(directories) if data.cache?(:directories)
            end
          end

          def run_rvm_use
            sh.raw "rvm use $(rvm current >&/dev/null) >&/dev/null"
          end

          def install
            sh.export 'CASHER_DIR', '$HOME/.casher'

            sh.mkdir '$CASHER_DIR/bin', echo: false, recursive: true
            sh.cmd "curl #{casher_url} #{debug_flags} -L -o #{BIN_PATH} -s --fail", retry: true, echo: 'Installing caching utilities'
            sh.raw "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > #{BIN_PATH}"

            sh.if "-f #{BIN_PATH}" do
              sh.chmod '+x', BIN_PATH, assert: false, echo: false
            end
          end

          def add(*paths)
            if paths
              paths.flatten.each_slice(ADD_DIR_MAX) { |dirs| run('add', dirs) }
            end
          end

          def fetch
            run('fetch', fetch_urls.map {|url| Shellwords.escape(url).to_s}, timing: true)
          end

          def fetch_urls
            urls = [
              fetch_url(group, true),
              fetch_url
            ]
            if data.pull_request
              urls << fetch_url(data.branch, true)
              urls << fetch_url(data.branch)
            end
            if data.branch != data.repository[:default_branch]
              urls << fetch_url(data.repository[:default_branch], true)
              urls << fetch_url(data.repository[:default_branch])
            end

            urls.uniq
          end

          def push
            run('push', Shellwords.escape(push_url.to_s), assert: false, timing: true)
          end

          def fetch_url(branch = group, extras = false)
            url('GET', prefixed(branch, extras), expires: fetch_timeout)
          end

          def push_url(branch = group)
            url('PUT', prefixed(branch, true), expires: push_timeout)
          end

          def fold(message = nil)
            @fold_count ||= 0
            @fold_count  += 1

            sh.fold "cache.#{@fold_count}" do
              sh.echo message if message
              yield
            end
          end

          private
            def host_proc
              raise "#{__method__} must be overridden"
            end

            def validate
              VALIDATE.each { |key, msg| msgs << msg unless data_store_options[key] }
              sh.echo MSGS[:config_missing] % [ self.class.name.split('::').last.upcase, msgs.join(', ')], ansi: :red unless msgs.empty?
            end

            def run(command, args, options = {})
              sh.with_errexit_off do
                sh.if "-f #{BIN_PATH}" do
                  sh.cmd('type rvm &>/dev/null || source ~/.rvm/scripts/rvm', echo: false, assert: false)
                  sh.cmd "rvm $(travis_internal_ruby) --fuzzy do #{BIN_PATH} #{command} #{Array(args).join(' ')}", options.merge(echo: false, assert: false)
                end
              end
            end

            def group
              data.pull_request ? "PR.#{data.pull_request}" : data.branch
            end

            def directories
              Array(data.cache[:directories])
            end

            def fetch_timeout
              cache_options.fetch(:fetch_timeout)
            end

            def push_timeout
              cache_options.fetch(:push_timeout)
            end

            def location(path)
              region = data_store_options.fetch(:region, 'us-east-1')
              Location.new(
                data_store_options.fetch(:scheme, 'https'),
                region,
                data_store_options.fetch(:bucket, ''),
                path,
                data_store_options.fetch(:hostname, host_proc.call(region)),
                data_store_options.fetch(:aws_signature_version, DEFAULT_AWS_SIGNATURE_VERSION).to_s
              )
            end

            def prefixed(branch, extras = false)
              slug_local = slug.dup
              if ! extras
                slug_local = slug.gsub(/^cache(.+?)(?=--)/,'cache')
              end

              case data_store_options.fetch(:aws_signature_version, DEFAULT_AWS_SIGNATURE_VERSION).to_s
              when '2'
                args = [data.github_id, branch, slug_local].compact
              else
                args = [data_store_options.fetch(:bucket, ''), data.github_id, branch, slug_local].compact
              end
              args.map! { |arg| arg.to_s.gsub(/[^\w\.\_\-]+/, '') }
              '/' << args.join('/') << '.tgz'
            end

            def url(verb, path, options = {})
              signature(verb, path, options).to_uri.to_s.untaint
            end

            def key_pair
              @key_pair ||= KeyPair.new(data_store_options[:access_key_id], data_store_options[:secret_access_key])
            end

            def data_store
              cache_options[:type]
            end

            def data_store_options
              cache_options[data_store.to_sym] || {}
            end

            def cache_options
              data.cache_options || {}
            end

            def casher_url
              CASHER_URL % casher_branch
            end

            def casher_branch
              if branch = data.cache[:branch]
                branch
              else
                data.cache?(:edge) ? 'master' : 'production'
              end
            end

            def debug_flags
              "-v -w '#{CURL_FORMAT}'" if data.cache[:debug]
            end
        end
      end
    end
  end
end
