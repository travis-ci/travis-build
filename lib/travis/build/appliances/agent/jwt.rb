require 'jwt'
require 'openssl'
require 'securerandom'

module Jwt
  class RefreshToken < Struct.new(:key, :job_id, :site)
    MAX_DURATION = 600
    ALG = 'RS512'

    def create
      ::JWT.encode(payload, key, ALG)
    end

    def rand
      @rand ||= SecureRandom.hex
    end

    private

      def payload
        {
          iss: 'build',
          typ: 'refresh',
          sub: job_id,
          exp: expires.to_i,
          site: site,
          rand: rand
        }
      end

      def expires
        Time.now.utc + MAX_DURATION
      end
  end
end
