module Travis
  module Vault
    class Keys
      class KV2
        def self.resolve(path, faraday_connection)
          response = faraday_connection.get("/v1/secret/data/#{path}")
          response.status == 200 ? JSON.parse(response.body).dig('data', 'data').to_json : nil
        end
      end
    end
  end
end
