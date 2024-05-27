require 'base64'
require 'ssh_data'

module Travis
  module Build
    class Data
      class SshKey < Struct.new(:value, :source, :encoded, :public_key)
        CUSTOM = %w(repository_settings travis_yaml)

        def value
          if encoded?
            Base64.decode64(super)
          else
            super
          end
        end

        def encoded?
          encoded
        end

        def custom?
          CUSTOM.include?(source)
        end

        def fingerprint
          @fingerprint ||= begin
            rsa_key = OpenSSL::PKey::RSA.new(value)
            public_ssh_rsa = "\x00\x00\x00\x07ssh-rsa" + rsa_key.e.to_s(0) + rsa_key.n.to_s(0)
            OpenSSL::Digest::MD5.new(public_ssh_rsa).hexdigest.scan(/../).join(':')
          end
        rescue OpenSSL::PKey::RSAError
          @fingerprint ||= handle_nonrsa(value)
        end

        def handle_nonrsa(key)
          parsed_key = SSHData::PrivateKey.parse_openssh(key)
          public_key = parsed_key[0]&.public_key
          return unless public_key

          bytes = if public_key.respond_to?(:public_key_bytes)
                    public_key.public_key_bytes
                  elsif public_key.respond_to?(:pk)
                    public_key.pk
                  end
          return unless bytes

          OpenSSL::Digest::MD5.new(bytes).hexdigest.scan(/../).join(':')
        rescue SSHData::DecodeError
        end

      end
    end
  end
end
