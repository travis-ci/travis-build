require 'rest-client'

module Travis
  module Vault
    class Connect
      def self.call(vault)
        response = RestClient.get("#{vault[:api_url]}/v1/auth/token/lookup-self", 'X-Vault-Token': vault[:token])
        raise ConnectionError if response.code != 200
      rescue RestClient::ExceptionWithResponse, SocketError
        raise ConnectionError
      end
    end
  end
end
