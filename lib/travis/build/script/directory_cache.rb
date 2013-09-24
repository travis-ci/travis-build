require 'openssl'
require 'digest/sha1'
require 'addressable/uri'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3
          # TODO: Switch to different branch from master?
          CASHER_URL = "https://raw.github.com/rkh/casher/master/bin/casher"

          attr_accessor :digest, :fetch_timeout, :push_timeout, :bucket, :secret_access_key, :access_key_id, :uri_parser, :host, :scheme, :job, :repository, :start

          def initialize(options, repository, job, start = Time.now)
            @digest            = OpenSSL::Digest::Digest.new('sha1')
            @fetch_timeout     = options.fetch(:fetch_timeout)
            @push_timeout      = options.fetch(:push_timeout)
            @bucket            = options[:s3].fetch(:bucket)
            @secret_access_key = options[:s3].fetch(:secret_access_key)
            @access_key_id     = options[:s3].fetch(:access_key_id)
            @scheme            = options[:s3][:scheme] || "https"
            @host              = options[:s3][:host]   || "s3.amazonaws.com"
            @job               = job
            @repository        = repository
            @start             = start
          end

          def install(sh)
            sh.cmd "export CASHER_DIR=$HOME/.casher", log: false, echo: false
            sh.cmd "mkdir -p $CASHER_DIR/bin", log: false, echo: false
            sh.cmd "curl #{CASHER_URL} -o #{binary}", echo: false
            sh.cmd "chmod +x #{binary}", log: false, echo: false
          end

          def add(sh, path)
            run(sh, "add", path) if path
          end

          def fetch(sh)
            run(sh, "fetch", fetch_url)
          end

          def push(sh)
            run(sh, "push", push_url)
          end

          def fetch_url
            url("GET", slug, expires: start + fetch_timeout)
          end

          def push_url
            url("PUT", slug, expires: start + push_timeout)
          end

          private

            def slug
              # this assumes that the job number is deterministic depending on the configuration
              repository.fetch(:github_id).to_s + "-" + job[:number].to_s
            end

            def url(verb, path, options = {})
              path    = bucket + path
              expires = Integer(options[:expires])
              string  = [ verb, options[:md5], options[:content_type], expires, path ].join("\n")
              hmac    = OpenSSL::HMAC.digest(digest, secret_access_key, string)
              Addressable::URI.new(host: host, scheme: scheme, path: path, query_values: {
                AWSAccessKeyId: access_key_id, Expires: expires, Signature: [hmac].pack("m0") })
            end

            def binary
              "$CASHER_DIR/bin/casher"
            end

            def run(sh, command, argument)
              sh.cmd("#{binary} #{command} #{argument}")
            end
        end

        class Dummy
          def method_missing(*)
            self
          end
        end

        def directory_cache
          @directory_cache ||= case type = data.cache_options[:type]
                               when :s3 then S3.new(data.cache_options, data.repository, data.job)
                               when nil then Dummy.new
                               else raise ArgumentError, "unknown caching mode %p" % type
                               end
        end

        def cache_directories
          return [] unless cache? :directories
          config[:cache]
        end

        def setup_directory_cache
          directory_cache.install(self)
          directory_cache.fetch(self)
          Array(data.cache[:directories]).each do |entry|
            directory_cache.add(self, entry)
          end if data.cache? :directories
        end

        def push_directory_cache
          # only publish cache from master
          return if data.branch != 'master'
          directory_cache.push(self)
        end
      end
    end
  end
end
