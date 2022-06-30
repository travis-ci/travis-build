module Vault
  class BuildPaths
    def initialize(secrets)
      @secrets = secrets
    end

    def build
      secrets.map { |secret| format_paths(secret) }.flatten.uniq
    end

    private

    def format_paths(secret)
      return secret if secret.is_a?(String)
      return [] if secret[:namespace].blank?

      namespace_name = secret[:namespace].find { |el| el[:name] }

      return secret[:namespace] if namespace_name.blank?

      paths = secret[:namespace].reject { |el| el[:name] }
      paths.map { |path| "#{namespace_name}/#{path}" }
    end

    attr_reader :secrets
  end
end
