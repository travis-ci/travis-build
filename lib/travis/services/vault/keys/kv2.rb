require 'travis/services/vault/config'

module Travis
  module Vault
    class Keys
      class KV2
        def self.resolve(path)
          conn = Faraday.new(
            url: Travis::Vault::Config.instance.api_url,
            headers: { 'X-Vault-Token' => Travis::Vault::Config.instance.token }
          )
          response = conn.get("/v1/secret/data/#{path}")
          response.status == 200 ? JSON.parse(response.body).dig('data', 'data').to_json : nil
        end
      end
    end
  end
end
