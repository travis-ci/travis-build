module Vault
  class Connect
    def self.call
      target = URI("#{ENV['VAULT_ADDR']}/v1/auth/token/lookup-self")
      req = Net::HTTP::Get.new(target)
      req['X-Vault-Token'] = ENV['VAULT_TOKEN']
      response = Net::HTTP.start(target.hostname, target.port, use_ssl: target.scheme == 'https') do |http|
        http.request(req)
      end
      raise ConnectionError if response.code != '200'
    end
  end
end
