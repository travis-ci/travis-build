module Travis
  module Vault
    class Connect
      def self.call(vault)
        faraday_connection = Faraday.new(
          url: vault[:api_url],
          headers: { 'X-Vault-Token' => vault[:token] }
        )
        response = faraday_connection.get('/v1/auth/token/lookup-self')
        raise ConnectionError if response.status != 200
      rescue Faraday::ConnectionFailed => _e
        raise ConnectionError
      end
    end
  end
end
