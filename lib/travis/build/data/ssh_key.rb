require 'base64'

module Travis
  module Build
    class Data
      class SshKey < Struct.new(:value, :source, :encoded)
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
        end
      end
    end
  end
end
