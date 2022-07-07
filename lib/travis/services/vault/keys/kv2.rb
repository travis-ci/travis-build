module Travis
  module Vault
    class Keys
      class KV2
        def self.resolve(path, vault)
          faraday_connection = Faraday.new(
            url: vault[:api_url],
            headers: { 'X-Vault-Token': vault[:token] }
          )
          response = faraday_connection.get("/v1/secret/data/#{path}")
          JSON.parse(response.body).dig('data', 'data').to_json if response.status == 200
        end
      end
    end
  end
end
