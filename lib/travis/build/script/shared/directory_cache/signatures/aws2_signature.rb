require 'uri'
require 'addressable/uri'
require 'digest/sha1'
require 'openssl'
require 'base64'
require 'time'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Signatures
          class AWS2Signature

            attr_reader :verb, :key_pair, :location, :expires, :access_id_param

            def initialize(key:, http_verb:, location:, expires:, access_id_param: 'AWSAccessKeyId', timestamp: Time.now, ext_headers: {})
              @key_pair = key
              @verb = http_verb.upcase
              @location = location
              @expires = expires
              @timestamp = timestamp
              @access_id_param = access_id_param
            end

            def to_uri
              Addressable::URI.new(
                scheme: location.scheme,
                host: location.hostname,
                path: location.path,
                query_values: query_params
              )
            end

            def sign
              hmac = OpenSSL::HMAC.new(@key_pair.secret, OpenSSL::Digest::SHA1.new)
              Base64.strict_encode64(
                hmac.update(
                  message(@verb, @date, @location.bucket, @location.path)
                ).digest
              )
            end

            private

            def canonical_headers(verb, date)
              [
                verb,
                '',
                '',
                expires
              ].join("\n")
            end

            def canonical_extension_headers(headers)
              # we will assume headers is a Hash,
              # which means each header is unique, and
              # we skip consolidating headers and their values intø a comma-separated list

              ret = {}
              str = []

              headers.each do |k,v|
                ret.merge!({k.downcase => v})
              end

              ret.sort.each do |k,v|
                str << "#{k}:#{v.gsub(/\r?\n/, ' ')}"
              end

              str.join("\n")
            end

            def message verb, date, bucket, path, ext_headers = {}
              "#{[
                canonical_headers(verb, date),
                canonical_extension_headers(ext_headers)
              ].delete_if { |el| el.empty? }.join("\n")}" <<
              "\n/#{bucket}#{path}"
            end

            def query_params
              {
                access_id_param => key_pair.id,
                'Expires' => expires,
                'Signature' => sign
              }
            end
          end
        end
      end
    end
  end
end
