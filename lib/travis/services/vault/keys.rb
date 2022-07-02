require 'travis/services/vault/keys/kv1'
require 'travis/services/vault/keys/kv2'

module Travis
  module Vault
    class Keys
      def initialize(vault, appliance)
        @vault = vault
        @appliance = appliance
      end

      def resolve
        return [] unless vault[:secrets]

        paths.each do |path|
          key_name = path.split('/').last
          value = Keys.const_get(version.upcase).resolve(path)
          if value.present?
            export(key_name, value, echo: true, secure: true)
          else
            echo *(warn_message(path))
          end
        end
      end

      private

      attr_reader :vault, :appliance

      delegate :export, :echo, to: 'appliance.sh'

      def warn_message(path)
        ["The value fetched for #{path} is blank.", ansi: :yellow]
      end

      def version
        vault[:secrets].find { |secret| secret.is_a?(Hash) && secret[:kv_api_ver] } || 'kv2'
      end

      def paths
        @paths ||= BuildPaths.new(vault[:secrets].reject { |secret| secret.is_a?(Hash) && secret[:kv_api_ver] }).call
      end
    end
  end
end
