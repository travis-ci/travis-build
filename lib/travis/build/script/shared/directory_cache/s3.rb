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
          CASHER_URL = "https://raw.githubusercontent.com/travis-ci/casher/%s/bin/casher"
          USE_RUBY   = "1.9.3"
          BIN_PATH   = "$CASHER_DIR/bin/casher"

          def initialize(data, slug, casher_branch, start = Time.now)
            @data = data
            @slug = slug
            @casher_branch = casher_branch
            @start = start
          end

          def install(sh)
            sh.export 'CASHER_DIR', '$HOME/.casher'

            sh.mkdir '$CASHER_DIR/bin', echo: false, recursive: true
            sh.cmd "curl #{CASHER_URL % @casher_branch} -L -o #{BIN_PATH} -s --fail", retry: true
            sh.cmd "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > #{BIN_PATH}"

            sh.if "-f #{BIN_PATH}" do
              sh.chmod '+x', BIN_PATH
            end
          end

          def add(sh, path)
            run(sh, 'add', path) if path
          end

          def fetch(sh)
            urls = [Shellwords.escape(fetch_url.to_s)]
            urls << Shellwords.escape(fetch_url('master').to_s) if @data.branch != 'master'
            urls << Shellwords.escape(fetch_url(nil).to_s)
            run(sh, 'fetch', *urls)
          end

          def push(sh)
            run(sh, 'push', Shellwords.escape(push_url.to_s))
          end

          def fetch_url(branch = @data.branch)
            url('GET', prefixed(branch), expires: fetch_timeout)
          end

          def push_url(branch = @data.branch)
            url('PUT', prefixed(branch), expires: push_timeout)
          end

          def fold(sh, message = nil)
            @fold_count ||= 0
            @fold_count  += 1

            sh.fold "cache.#{@fold_count}" do
              sh.echo message if message
              yield
            end
          end

          private

            def fetch_timeout
              @data.cache_options.fetch(:fetch_timeout)
            end

            def push_timeout
              @data.cache_options.fetch(:push_timeout)
            end

            def location(path)
              Location.new(
                @data.cache_options[:s3].fetch(:scheme, "https"),
                @data.cache_options[:s3].fetch(:region, "us-east-1"),
                @data.cache_options[:s3].fetch(:bucket),
                path
              )
            end

            def prefixed(branch)
              args = [@data.repository.fetch(:github_id), branch, @slug].compact
              args.map! { |a| a.to_s.gsub(/[^\w\.\_\-]+/, '') }
              "/" << args.join("/") << ".tbz"
            end

            def url(verb, path, options = {})
              @key_pair ||= KeyPair.new(@data.cache_options[:s3].fetch(:access_key_id), @data.cache_options[:s3].fetch(:secret_access_key))
              AWS4Signature.new(@key_pair, verb, location(path), options[:expires], @start).to_uri
            end

            def run(sh, command, *arguments)
              sh.if "-f #{BIN_PATH}" do
                sh.cmd "rvm #{USE_RUBY} --fuzzy do #{BIN_PATH} #{command} #{arguments.join(" ")}", echo: false
              end
            end
        end
      end
    end
  end
end
