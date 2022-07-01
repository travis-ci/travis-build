module Vault
  class Keys
    class KV1
      def self.get(path)
        target = URI("#{ENV['VAULT_ADDR']}/v1/secret/#{path}")
        req = Net::HTTP::Get.new(target)
        req['X-Vault-Token'] = ENV['VAULT_TOKEN']
        result = Net::HTTP.start(target.hostname, target.port, use_ssl: target.scheme == 'https') do |http|
          http.request(req)
        end

        JSON.parse(result.body)
      end
    end
  end
end
