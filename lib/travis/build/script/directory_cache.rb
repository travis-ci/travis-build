require 'openssl'
require 'base64'
require 'digest/sha1'
require 'addressable/uri'
require 'shellwords'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3
          # TODO: Switch to different branch from master?
          CASHER_URL = "https://raw.github.com/travis-ci/casher/%s/bin/casher"
          USE_RUBY   = "1.9.3"

          attr_accessor :fetch_timeout, :push_timeout, :bucket, :secret_access_key, :access_key_id, :uri_parser, :host, :scheme, :slug, :data, :start, :casher_url

          def initialize(data, slug, casher_branch, start = Time.now)
            @fetch_timeout     = data.cache_options.fetch(:fetch_timeout)
            @push_timeout      = data.cache_options.fetch(:push_timeout)
            @bucket            = data.cache_options[:s3].fetch(:bucket)
            @secret_access_key = data.cache_options[:s3].fetch(:secret_access_key)
            @access_key_id     = data.cache_options[:s3].fetch(:access_key_id)
            @scheme            = data.cache_options[:s3][:scheme] || "https"
            @host              = data.cache_options[:s3][:host]   || "s3.amazonaws.com"
            @slug              = slug
            @data              = data
            @start             = start
            @casher_url        = CASHER_URL % casher_branch
          end

          def install(sh)
            sh.cmd "export CASHER_DIR=$HOME/.casher", log: false, echo: false
            sh.cmd "mkdir -p $CASHER_DIR/bin", log: false, echo: false
            sh.cmd "curl #{casher_url} -o #{binary} -s --fail", echo: false, log: false, retry: true, assert: false
            sh.cmd "[ $? -ne 0 ] && echo 'Failed to fetch casher from GitHub, disabling cache.' && echo > #{binary}", echo: false, log: false, assert: false
            sh.cmd "chmod +x #{binary}", log: false, echo: false
          end

          def add(sh, path)
            run(sh, "add", path) if path
          end

          def fetch(sh)
            urls = [Shellwords.escape(fetch_url.to_s)]
            urls << Shellwords.escape(fetch_url('master').to_s) if data.branch != 'master'
            urls << Shellwords.escape(fetch_url(nil).to_s)
            run(sh, "fetch", *urls)
          end

          def push(sh)
            run(sh, "push", Shellwords.escape(push_url.to_s))
          end

          def fetch_url(branch = data.branch)
            url("GET", prefixed(branch), expires: start + fetch_timeout)
          end

          def push_url(branch = data.branch)
            url("PUT", prefixed(branch), expires: start + push_timeout)
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

            def prefixed(branch)
              args = [data.repository.fetch(:github_id), branch, slug].compact
              args.map! { |a| a.to_s.gsub(/[^\w\.\_\-]+/, '') }
              File.join(*args)<< ".tbz"
            end

            def url(verb, path, options = {})
              path    = File.join("/", bucket, path)
              expires = Integer(options[:expires])
              string  = [ verb, options[:md5], options[:content_type], expires, path ].join("\n")
              hmac    = OpenSSL::HMAC.digest('sha1', secret_access_key, string)
              Addressable::URI.new(host: host, scheme: scheme, path: path, query_values: {
                AWSAccessKeyId: access_key_id, Expires: expires, Signature: Base64.encode64(hmac).strip })
            end

            def binary
              "$CASHER_DIR/bin/casher"
            end

            def run(sh, command, *arguments)
              sh.cmd("rvm #{USE_RUBY} do #{binary} #{command} #{arguments.join(" ")}", echo: false)
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
