module Travis
  module Vault
    class Keys
      class BuildPaths
        def initialize(secrets)
          @secrets = secrets
        end

        def call
          secrets.map { |secret| format_paths(secret) }.flatten.reverse.uniq { |path| path.split('/').last }
        end

        private

        def format_paths(secret)
          return secret if secret.is_a?(String)
          return [] if secret[:namespace].blank?

          namespace_name = (secret[:namespace].find { |el| el.is_a?(Hash) && el[:name] } || {})[:name]

          return secret[:namespace] if namespace_name.blank?

          paths = secret[:namespace].reject { |el| el.is_a?(Hash) && el[:name] }
          paths.map { |path| "#{namespace_name}/#{path}" }
        end

        attr_reader :secrets
      end
    end
  end
end
