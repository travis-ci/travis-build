require 'rest-client'

module Travis
  module Vault
    class Keys
      class KV1
        def self.resolve(path, vault)
          response = RestClient.get("#{vault[:api_url]}/v1/secret/#{path}", 'X-Vault-Token': vault[:token])
          JSON.parse(response.body)['data'].to_json if response.code == 200
        rescue RestClient::ExceptionWithResponse, SocketError
          nil
        end
      end
    end
  end
end
