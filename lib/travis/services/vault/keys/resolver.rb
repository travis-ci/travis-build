module Travis
  module Vault
    class Keys
      class Resolver
        attr_reader :paths, :version, :appliance

        delegate :data, to: :appliance
        delegate :vault, to: :appliance
        delegate :export, :echo, to: :'appliance.sh'

        def initialize(paths, version, appliance)
          @paths = paths
          @version = version
          @appliance = appliance
        end

        def call
          return if paths.blank?

          namespace = nil
          vault_secrets = []

          if appliance.vault.is_a?(Hash)
            secrets = appliance.vault[:secrets]
            namespace = secrets[:namespace].find { |el| el.is_a?(Hash) && el&.dig(:name) }&.dig(:name) if secrets&.include?(:namespace)
          end
          paths.each do |path|
            parts = path.split('/',2)
            mount = parts&.first
            path = parts&.last
            secret_data = Keys.const_get(version.upcase).resolve(namespace, mount, path, vault)
            if secret_data.present?
              secret_name = path.split('/').last
              secret_data.each do |key, value|
                env_name = key
                env_name = [secret_name, env_name].join('_') if true # To-Do: Make the prepend customizable from .travis.yml
                env_name = (path.split('/') << env_name).join('_') if false # To-Do: Make the prepend customizable from .travis.yml
                env_name.gsub!(/[^0-9a-zA-Z]/,'_')
                export(env_name.upcase, %("#{value}"), echo: false, secure: true)
                vault_secrets << value
              end
            else
              echo *(warn_message(path))
            end
          end

          data.vault_secrets = vault_secrets.uniq if vault_secrets.present?
        end

        private

        def warn_message(path)
          ["The value fetched for #{path} is blank.", ansi: :yellow]
        end
      end
    end
  end
end
