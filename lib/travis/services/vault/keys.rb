require 'travis/services/vault/keys/kv1'
require 'travis/services/vault/keys/kv2'

require 'travis/services/vault/keys/paths'
require 'travis/services/vault/keys/version'
require 'travis/services/vault/keys/resolver'

module Travis
  module Vault
    class Keys

      attr_reader :appliance, :faraday_connection

      def initialize(appliance)
        @appliance = appliance
      end

      def resolve
        paths = Paths.call(appliance.vault)
        version = Version.call(appliance.vault)
        Resolver.new(paths, version, appliance).call
      end
    end
  end
end
