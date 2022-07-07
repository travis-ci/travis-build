module Travis
  module Vault
    class Keys
      class KV2
        def self.resolve(path, vault)
          response = RestClient::Request.execute(method: :get,
                                                 url: "#{vault[:api_url]}/v1/secret/data/#{path}",
                                                 headers: { 'X-Vault-Token': vault[:token] })
          JSON.parse(response.body).dig('data', 'data').to_json if response.code == 200
        rescue RestClient::ExceptionWithResponse => _e
          nil
        end
      end
    end
  end
end
