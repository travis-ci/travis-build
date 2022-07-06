require 'travis/services/vault/keys/kv1'
require 'travis/services/vault/keys/kv2'

require 'travis/services/vault/keys/paths'
require 'travis/services/vault/keys/version'
require 'travis/services/vault/keys/resolver'

module Travis
  module Vault
    class Keys
      def initialize(vault, appliance)
        @vault = vault
        @appliance = appliance
      end

      def resolve
        paths = Paths.call(vault)
        version = Version.call(vault)
        Resolver.new(paths, version, appliance).call
      end

      private

      attr_reader :vault, :appliance
    end
  end
end
