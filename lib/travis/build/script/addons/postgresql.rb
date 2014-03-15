module Travis
  module Build
    class Script
      module Addons
        class Postgresql
          def initialize(script, config)
            @script = script
            @postgresql_version = config.to_s
          end

          def before_install
            @script.fold('postgresql') do |script|
              script.cmd "sudo #{BIN_PATH}/travis-addon-postgresql #{@postgresql_version}", assert: true, echo: false
            end
          end
        end
      end
    end
  end
end

