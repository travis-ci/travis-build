require 'rest-client'

module Travis
  module Vault
    class Keys
      class KV1
        def self.resolve(namespace, mount, path, vault)
          response = RestClient.get("#{vault[:api_url]}/v1/#{mount}/#{path}", 'X-Vault-Token': vault[:token], 'X-Vault-Namespace': namespace ? namespace : "")
          JSON.parse(response.body)['data'] if response.code == 200
        rescue RestClient::ExceptionWithResponse, SocketError
          nil
        end
      end
    end
  end
end
