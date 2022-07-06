require 'travis/services/vault/config'

module Travis
  module Vault
    class Connect
      def self.call
        conn = Faraday.new(
          url: Travis::Vault::Config.instance.api_url,
          headers: {'X-Vault-Token' => Travis::Vault::Config.instance.token}
        )
        response = conn.get('/v1/auth/token/lookup-self')
        raise ConnectionError if response.status != 200
      rescue Faraday::ConnectionFailed => _e
        raise ConnectionError
      end
    end
  end
end
