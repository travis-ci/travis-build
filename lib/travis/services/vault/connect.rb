module Travis
  module Vault
    class Connect
      def self.call(faraday_connection)
        response = faraday_connection.get('/v1/auth/token/lookup-self')
        raise ConnectionError if response.status != 200
      rescue Faraday::ConnectionFailed => _e
        raise ConnectionError
      end
    end
  end
end
