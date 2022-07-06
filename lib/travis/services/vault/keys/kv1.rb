module Travis
  module Vault
    class Keys
      class KV1
        def self.resolve(path)
          conn = Faraday.new(
            url: ENV['VAULT_ADDR'],
            headers: { 'X-Vault-Token' => ENV['VAULT_TOKEN'] }
          )
          response = conn.get("/v1/secret/#{path}")
          response.status == 200 ? JSON.parse(response.body)['data'].to_json : nil
        end
      end
    end
  end
end
