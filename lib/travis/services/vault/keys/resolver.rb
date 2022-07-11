module Travis
  module Vault
    class Keys
      class Resolver
        MAX_KEYS_COUNT = 14

        attr_reader :paths, :version, :appliance

        delegate :export, :echo, to: 'appliance.sh'

        def initialize(paths, version, appliance)
          @paths = paths
          @version = version
          @appliance = appliance
        end

        def call
          return if paths.blank?

          paths.each do |path|
            if (value = Keys.const_get(version.upcase).resolve(path, appliance.vault))
              raise Travis::Vault::RootKeyError if value.keys.size > MAX_KEYS_COUNT
              key_name = path.split('/').last.upcase
              export(key_name, "'#{value.to_json}'", echo: true, secure: true)
            else
              echo *(warn_message(path))
            end
          end
        end

        private

        def warn_message(path)
          ["The value fetched for #{path} is blank.", ansi: :yellow]
        end
      end
    end
  end
end
