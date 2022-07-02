module Travis
  module Vault
    class Keys
      class KV1
        def self.resolve(path)
          target = URI("#{ENV['VAULT_ADDR']}/v1/secret/#{path}")
          req = Net::HTTP::Get.new(target)
          req['X-Vault-Token'] = ENV['VAULT_TOKEN']
          result = Net::HTTP.start(target.hostname, target.port, use_ssl: target.scheme == 'https') do |http|
            http.request(req)
          end

          result.code == '200' ? JSON.parse(result.body)['data'].to_json : nil
        end
      end
    end
  end
end
