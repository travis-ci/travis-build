require 'travis/services/vault/keys/build_paths'

module Travis
  module Vault
    class Keys
      class Paths
        def self.call(vault)
          paths = vault[:secrets].reject { |secret| secret.is_a?(Hash) && secret[:kv_api_ver] }

          BuildPaths.new(paths).call
        end
      end
    end
  end
end
