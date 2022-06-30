require 'travis/services/vault/keys/kv1'
require 'travis/services/vault/keys/kv2'

module Vault
  class Keys
    def self.get(vault)
      return [] unless vault[:secrets]

      version = vault[:secrets].find { |secret| secret[:kv_api_ver]  } || 'kv2'
      paths = BuildPaths.new(vault[:secrets].reject { |secret| secret[:kv_api_ver] }).build
      Keys.const_get(version.upcase).get(paths)
    end
  end
end
