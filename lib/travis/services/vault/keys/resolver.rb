require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string/inflections'

module Travis
  module Vault
    class Keys
      class Resolver
        ENV_NAME_REGEX = /^[a-zA-Z_][a-zA-Z0-9_]*$/.freeze

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

          vault_secrets = []

          paths.each do |path|
            secret_data = Keys.const_get(version.upcase).resolve(path, vault)
            if secret_data.present?
              secret_name = path.split('/').last
              secret_data.each do |key, value|
                env_name = key
                env_name = [secret_name, env_name].join('_') if true # To-Do: Make the prepend customizable from .travis.yml
                env_name = (path.split('/') << env_name).join('_') if false # To-Do: Make the prepend customizable from .travis.yml
                if env_name.match?(ENV_NAME_REGEX)
                  export(env_name.upcase, %("#{value}"), echo: false, secure: true)
                  vault_secrets << value
                else
                  echo *warn_message("The env name #{env_name} is invalid. Valid chars: a-z, A-Z, 0-9 and _. May NOT begin with a number.")
                end
              end
            else
              echo *warn_message("The value fetched for #{path} is blank.")
            end
          end

          data.vault_secrets = vault_secrets.uniq if vault_secrets.present?
        end

        private

        def warn_message(message)
          [message, ansi: :yellow]
        end
      end
    end
  end
end
