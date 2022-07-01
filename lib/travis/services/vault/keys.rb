require 'travis/services/vault/keys/kv1'
require 'travis/services/vault/keys/kv2'

module Travis
  module Vault
    class Keys
      def self.get(vault, vault_keys)
        return [] unless vault[:secrets]
        version = vault[:secrets].find { |secret| secret.is_a?(Hash) && secret[:kv_api_ver] } || 'kv2'
        paths = BuildPaths.new(vault[:secrets].reject { |secret| secret.is_a?(Hash) && secret[:kv_api_ver] }).build
        paths.each do |path|
          key_name = path.split('/').last
          value = Keys.const_get(version.upcase).get(path)
          vault_keys.sh.export(key_name, value, echo: true, secure: true)
        end
      end
    end
  end
end
