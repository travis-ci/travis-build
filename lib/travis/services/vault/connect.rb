require 'rest-client'

module Travis
  module Vault
    class Connect
      def self.call(vault)
        response = RestClient::Request.execute(method: :get,
                                               url: "#{vault[:api_url]}/v1/auth/token/lookup-self",
                                               headers: { 'X-Vault-Token': vault[:token] })
        raise ConnectionError if response.code != 200
      rescue RestClient::ExceptionWithResponse, SocketError => _e
        raise ConnectionError
      end
    end
  end
end
