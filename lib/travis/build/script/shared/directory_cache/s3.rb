require 'shellwords'

require 'travis/build/script/shared/directory_cache/s3/aws4_signature'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3
          KeyPair = Struct.new(:id, :secret)

          Location = Struct.new(:scheme, :region, :bucket, :path) do
            def hostname
              "#{bucket}.#{region == 'us-east-1' ? 's3' : "s3-#{region}"}.amazonaws.com"
            end
          end

          # TODO: Switch to different branch from master?
          CASHER_URL = 'https://raw.githubusercontent.com/travis-ci/casher/%s/bin/casher'
          USE_RUBY   = '1.9.3'
          BIN_PATH   = '$CASHER_DIR/bin/casher'

          attr_reader :sh, :data, :slug, :start

          def initialize(sh, data, slug, start = Time.now)
            @sh = sh
            @data = data
            @slug = slug
            @start = start
          end

          def setup
            fold 'Setting up build cache' do
              install
              fetch
              directories.each { |dir| add(dir) } if data.cache?(:directories)
            end
          end

          def install
            sh.export 'CASHER_DIR', '$HOME/.casher'

            sh.mkdir '$CASHER_DIR/bin', echo: false, recursive: true
            sh.cmd "curl #{casher_url} -L -o #{BIN_PATH} -s --fail", retry: true, display: 'Installing caching utilities'
            sh.cmd "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > #{BIN_PATH}"

            sh.if "-f #{BIN_PATH}" do
              sh.chmod '+x', BIN_PATH
            end
          end

          def add(path)
            run('add', path) if path
          end

          def fetch
            urls = [Shellwords.escape(fetch_url.to_s)]
            urls << Shellwords.escape(fetch_url(data.branch).to_s) if data.pull_request
            urls << Shellwords.escape(fetch_url('master').to_s)    if data.branch != 'master'
            run('fetch', *urls)
          end

          def push
            run('push', Shellwords.escape(push_url.to_s))
          end

          def fetch_url(branch = group)
            url('GET', prefixed(branch), expires: fetch_timeout)
          end

          def push_url(branch = group)
            url('PUT', prefixed(branch), expires: push_timeout)
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

            def run(command, *arguments)
              sh.if "-f #{BIN_PATH}" do
                sh.cmd "rvm #{USE_RUBY} --fuzzy do #{BIN_PATH} #{command} #{arguments.join(' ')}", echo: false
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

            def prefixed(branch)
              args = [data.github_id, branch, slug].compact
              args.map! { |arg| arg.to_s.gsub(/[^\w\.\_\-]+/, '') }
              '/' << args.join('/') << '.tbz'
            end

            def url(verb, path, options = {})
              AWS4Signature.new(key_pair, verb, location(path), options[:expires], start).to_uri
            end

            def key_pair
              KeyPair.new(s3_options[:access_key_id], s3_options[:secret_access_key])
            end

            def s3_options
              options.fetch(:s3)
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
        end
      end
    end
  end
end
