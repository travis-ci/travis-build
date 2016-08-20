require 'uri'
require 'addressable/uri'
require 'digest/sha1'
require 'openssl'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Signatures
          class AWS4Signature
            def initialize(key:, http_verb:, location:, expires:, timestamp: Time.now)
              @key_pair = key
              @verb = http_verb
              @location = location
              @expires = expires
              @timestamp = timestamp
            end

            def to_uri
              query = canonical_query_params.dup
              query["X-Amz-Signature"] = OpenSSL::HMAC.hexdigest("sha256", signing_key, string_to_sign)

              Addressable::URI.new(
                scheme: @location.scheme,
                host: @location.host,
                path: @location.path,
                query_values: query,
              )
            end

            private

            def date
              @timestamp.utc.strftime('%Y%m%d')
            end

            def timestamp
              @timestamp.utc.strftime('%Y%m%dT%H%M%SZ')
            end

            def query_string
              canonical_query_params.map { |key, value|
                "#{URI.encode(key.to_s, /[^~a-zA-Z0-9_.-]/)}=#{URI.encode(value.to_s, /[^~a-zA-Z0-9_.-]/)}"
              }.join('&')
            end

            def request_sha
              OpenSSL::Digest::SHA256.hexdigest(
                [
                  @verb,
                  @location.path,
                  query_string,
                  "host:#{@location.hostname}\n",
                  'host',
                  'UNSIGNED-PAYLOAD'
                ].join("\n")
              )
            end

            def canonical_query_params
              @canonical_query_params ||= {
                'X-Amz-Algorithm' => 'AWS4-HMAC-SHA256',
                'X-Amz-Credential' => "#{@key_pair.id}/#{date}/#{@location.region}/s3/aws4_request",
                'X-Amz-Date' => timestamp,
                'X-Amz-Expires' => @expires,
                'X-Amz-SignedHeaders' => 'host',
              }
            end

            def string_to_sign
              [
                'AWS4-HMAC-SHA256',
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
                's3',
                'aws4_request',
              )
            end

            def recursive_hmac(*args)
              args.inject { |key, data| OpenSSL::HMAC.digest('sha256', key, data) }
            end
          end
        end
      end
    end
  end
end
