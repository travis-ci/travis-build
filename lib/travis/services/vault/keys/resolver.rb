module Travis
  module Vault
    class Keys
      class Resolver

        attr_reader :paths, :version, :appliance, :faraday_connection

        delegate :export, :echo, to: 'appliance.sh'

        def initialize(paths, version, appliance, faraday_connection)
          @paths = paths
          @version = version
          @appliance = appliance
          @faraday_connection = faraday_connection
        end

        def call
          return if paths.blank?

          paths.each do |path|
            if (value = Keys.const_get(version.upcase).resolve(path, faraday_connection))
              key_name = path.split('/').last.upcase
              export(key_name, value, echo: true, secure: true)
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
