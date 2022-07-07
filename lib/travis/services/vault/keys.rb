require 'travis/services/vault/keys/kv1'
require 'travis/services/vault/keys/kv2'

require 'travis/services/vault/keys/paths'
require 'travis/services/vault/keys/version'
require 'travis/services/vault/keys/resolver'

module Travis
  module Vault
    class Keys

      attr_reader :vault, :appliance, :faraday_connection

      def initialize(vault, appliance)
        @vault = vault
        @appliance = appliance
      end

      def resolve
        faraday_connection = Faraday.new(
          url: vault[:api_url],
          headers: {'X-Vault-Token' => vault[:token]}
        )
        paths = Paths.call(vault)
        version = Version.call(vault)
        Resolver.new(paths, version, appliance, faraday_connection).call
      end
    end
  end
end
