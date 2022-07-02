module Travis
  module Vault
    class Keys
      class Version
        def self.call(vault)
          vault[:secrets].find { |secret| secret.is_a?(Hash) && secret[:kv_api_ver] } || 'kv2'
        end
      end
    end
  end
end