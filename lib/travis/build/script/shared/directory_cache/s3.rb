require 'shellwords'

require 'travis/build/script/shared/directory_cache/s3/aws4_signature'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3
          MSGS = {
            config_missing: 'Worker S3 config missing: %s'
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

          # maximum number of directories to be 'added' to cache via casher
          # in one invocation
          ADD_DIR_MAX = 100

          KeyPair = Struct.new(:id, :secret)

          Location = Struct.new(:scheme, :region, :bucket, :path) do
            def hostname
              "#{bucket}.#{region == 'us-east-1' ? 's3' : "s3-#{region}"}.amazonaws.com"
            end
          end

          CASHER_URL = 'https://raw.githubusercontent.com/travis-ci/casher/%s/bin/casher'
          USE_RUBY   = '1.9.3'
          BIN_PATH   = '$CASHER_DIR/bin/casher'

          attr_reader :sh, :data, :slug, :start, :msgs

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

          def setup
            fold 'Setting up build cache' do
              install
              fetch
              add(directories) if data.cache?(:directories)
            end
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
            urls = [
              Shellwords.escape(fetch_url(group, '.tgz').to_s),
              Shellwords.escape(fetch_url.to_s)
            ]
            if data.pull_request
              urls << Shellwords.escape(fetch_url(data.branch, '.tgz').to_s)
              urls << Shellwords.escape(fetch_url(data.branch).to_s)
            end
            if data.branch != 'master'
              urls << Shellwords.escape(fetch_url('master', '.tgz').to_s)
              urls << Shellwords.escape(fetch_url('master').to_s)
            end
            run('fetch', urls, timing: true)
          end

          def push
            run('push', Shellwords.escape(push_url.to_s), assert: false, timing: true)
          end

          def fetch_url(branch = group, ext = '.tbz')
            url('GET', prefixed(branch, ext), expires: fetch_timeout)
          end

          def push_url(branch = group)
            url('PUT', prefixed(branch, '.tgz'), expires: push_timeout)
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

            def validate
              VALIDATE.each { |key, msg| msgs << msg unless s3_options[key] }
              sh.echo MSGS[:config_missing] % msgs.join(', '), ansi: :red unless msgs.empty?
            end

            def run(command, args, options = {})
              sh.if "-f #{BIN_PATH}" do
                sh.cmd('type rvm &>/dev/null || source ~/.rvm/scripts/rvm', echo: false, assert: false)
                sh.cmd "rvm #{USE_RUBY} --fuzzy do #{BIN_PATH} #{command} #{Array(args).join(' ')}", options.merge(echo: false)
              end
            end

            def group
              data.pull_request ? "PR.#{data.pull_request}" : data.branch
            end

            def directories
              Array(data.cache[:directories])
            end

            def fetch_timeout
              options.fetch(:fetch_timeout)
            end

            def push_timeout
              options.fetch(:push_timeout)
            end

            def location(path)
              Location.new(
                s3_options.fetch(:scheme, 'https'),
                s3_options.fetch(:region, 'us-east-1'),
                s3_options.fetch(:bucket),
                path
              )
            end

            def prefixed(branch, ext = '.tgz')
              args = [data.github_id, branch, slug].compact
              args.map! { |arg| arg.to_s.gsub(/[^\w\.\_\-]+/, '') }
              '/' << args.join('/') << ext
            end

            def url(verb, path, options = {})
              AWS4Signature.new(key_pair, verb, location(path), options[:expires], start).to_uri.to_s.untaint
            end

            def key_pair
              KeyPair.new(s3_options[:access_key_id], s3_options[:secret_access_key])
            end

            def s3_options
              options[:s3] || {}
            end

            def options
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
