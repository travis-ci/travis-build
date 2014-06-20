require 'openssl'
require 'base64'
require 'digest/sha1'
require 'addressable/uri'
require 'shellwords'
require 'uri'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3
          Location = Struct.new(:scheme, :region, :bucket, :path) do
            def hostname
              if region == "us-east-1"
                "#{bucket}.s3.amazonaws.com"
              else
                "#{bucket}.s3-#{region}.amazonaws.com"
              end
            end
          end

          KeyPair = Struct.new(:id, :secret)

          class AWS4Signature
            def initialize(key_pair, verb, location, expires, timestamp=Time.now)
              @key_pair = key_pair
              @verb = verb
              @location = location
              @expires = expires
              @timestamp = timestamp
            end

            def to_uri
              query = canonical_query_params.dup
              query["X-Amz-Signature"] = OpenSSL::HMAC.hexdigest("sha256", signing_key, string_to_sign)

              Addressable::URI.new(
                scheme: @location.scheme,
                host: @location.hostname,
                path: @location.path,
                query_values: query,
              )
            end

            private

            def date
              @timestamp.utc.strftime("%Y%m%d")
            end

            def timestamp
              @timestamp.utc.strftime("%Y%m%dT%H%M%SZ")
            end

            def query_string
              canonical_query_params.map { |key, value|
                "#{URI.encode(key.to_s, /[^~a-zA-Z0-9_.-]/)}=#{URI.encode(value.to_s, /[^~a-zA-Z0-9_.-]/)}"
              }.join("&")
            end

            def request_sha
              OpenSSL::Digest::SHA256.hexdigest(
                [
                  @verb,
                  @location.path,
                  query_string,
                  "host:#{@location.hostname}\n",
                  "host",
                  "UNSIGNED-PAYLOAD"
                ].join("\n")
              )
            end

            def canonical_query_params
              @canonical_query_params ||= {
                "X-Amz-Algorithm" => "AWS4-HMAC-SHA256",
                "X-Amz-Credential" => "#{@key_pair.id}/#{date}/#{@location.region}/s3/aws4_request",
                "X-Amz-Date" => timestamp,
                "X-Amz-Expires" => @expires,
                "X-Amz-SignedHeaders" => "host",
              }
            end

            def string_to_sign
              [
                "AWS4-HMAC-SHA256",
                timestamp,
                "#{date}/#{@location.region}/s3/aws4_request",
                request_sha
              ].join("\n")
            end

            def signing_key
              @signing_key ||= recursive_hmac(
                "AWS4#{@key_pair.secret}",
                date,
                @location.region,
                "s3",
                "aws4_request",
              )
            end

            def recursive_hmac(*args)
              args.inject { |key, data| OpenSSL::HMAC.digest("sha256", key, data) }
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
            sh.cmd "export CASHER_DIR=$HOME/.casher", log: false, echo: false
            sh.cmd "mkdir -p $CASHER_DIR/bin", log: false, echo: false
            sh.cmd "curl #{CASHER_URL % @casher_branch} -L -o #{BIN_PATH} -s --fail", echo: false, log: false, retry: true, assert: false
            sh.cmd "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > #{BIN_PATH}", echo: false, log: false, assert: false
            sh.if("-f #{BIN_PATH}") { |sh| sh.cmd "chmod +x #{BIN_PATH}", log: false, echo: false }
          end

          def add(sh, path)
            run(sh, "add", path) if path
          end

          def fetch(sh)
            urls = [Shellwords.escape(fetch_url.to_s)]
            urls << Shellwords.escape(fetch_url('master').to_s) if @data.branch != 'master'
            urls << Shellwords.escape(fetch_url(nil).to_s)
            run(sh, "fetch", *urls)
          end

          def push(sh)
            run(sh, "push", Shellwords.escape(push_url.to_s))
          end

          def fetch_url(branch = @data.branch)
            url("GET", prefixed(branch), expires: fetch_timeout)
          end

          def push_url(branch = @data.branch)
            url("PUT", prefixed(branch), expires: push_timeout)
          end

          def fold(sh, message = nil)
            @fold_count ||= 0
            @fold_count  += 1
            sh.fold("cache.#{@fold_count}") do
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
              sh.if("-f #{BIN_PATH}") do |sh|
                sh.cmd("rvm #{USE_RUBY} --fuzzy do #{BIN_PATH} #{command} #{arguments.join(" ")}", echo: false)
              end
            end
        end

        class Dummy
          def initialize(*)
          end

          def method_missing(*)
            self
          end
        end

        def directory_cache
          @directory_cache ||= cache_class.new(data, cache_slug, casher_branch)
        end

        def cache_class
          type = data.cache_options[:type].to_s.capitalize
          type = "Dummy" if type.empty? or !use_directory_cache?
          raise ArgumentError, "unknown caching mode %p" % type unless DirectoryCache.const_defined?(type, false)
          DirectoryCache.const_get(type)
        end

        def use_directory_cache?
          data.cache?(:directories)
        end

        def setup_directory_cache
          directory_cache.fold(self, "setup build cache") do
            directory_cache.install(self)
            directory_cache.fetch(self)
            Array(data.cache[:directories]).each do |entry|
              directory_cache.add(self, entry)
            end if data.cache? :directories
          end
        end

        def prepare_cache
        end

        def casher_branch
          data.cache?(:edge) ? 'master' : 'production'
        end

        def push_directory_cache
          # only publish cache from pushes to master
          return if data.pull_request
          directory_cache.fold(self, "store build cache") do
            prepare_cache
            directory_cache.push(self)
          end
        end
      end
    end
  end
end
