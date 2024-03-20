require 'rest-client'

module Travis
  module Vault
    class Keys
      class KV2
        def self.resolve(namespace, mount ,path, vault)
          response = RestClient.get("#{vault[:api_url]}/v1/#{mount}/data/#{path}", 'X-Vault-Token': vault[:token], 'X-Vault-Namespace': namespace ? namespace : "")
          JSON.parse(response.body).dig('data', 'data') if response.code == 200
        rescue RestClient::ExceptionWithResponse, SocketError
          nil
        end
      end
    end
  end
end
