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
          return nil unless parsed_key && parsed_key.length

          bytes = if parsed_key[0]&.public_key.respond_to?(:public_key_bytes)
                    parsed_key[0]&.public_key.public_key_bytes
                  elsif parsed_key[0]&.public_key.respond_to?(:pk)
                    parsed_key[0]&.public_key.pk
                  else
                    nil
                  end
          return nil unless bytes

          OpenSSL::Digest::MD5.new(bytes).hexdigest.scan(/../).join(':')
        rescue SSHData::DecodeError
          nil
        end

      end
    end
  end
end
