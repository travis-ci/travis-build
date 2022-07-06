module Travis
  module Vault
    class Connect
      def self.call
        conn = Faraday.new(
          url: ENV['VAULT_ADDR'],
          headers: {'X-Vault-Token' => ENV['VAULT_TOKEN']}
        )
        response = conn.get('/v1/auth/token/lookup-self')
        raise ConnectionError if response.status != 200
      rescue Faraday::ConnectionFailed => _e
        raise ConnectionError
      end
    end
  end
end
