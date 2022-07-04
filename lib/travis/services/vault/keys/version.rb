module Travis
  module Vault
    class Keys
      class Version
        DEFAULT_VALUE = 'kv2'.freeze

        def self.call(vault)
          vault[:secrets].find { |secret| secret.is_a?(Hash) && secret[:kv_api_ver] }&.values&.first || DEFAULT_VALUE
        end
      end
    end
  end
end