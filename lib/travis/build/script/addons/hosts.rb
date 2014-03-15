module Travis
  module Build
    class Script
      module Addons
        class Hosts
          def initialize(script, config)
            @script = script
            @config = [config].flatten
          end

          def setup
            @script.fold("hosts") do |script|
              script.cmd "sudo #{BIN_PATH}/travis-addon-hosts #{@config.join(' ')}", assert: true, echo: false
            end
          end
        end
      end
    end
  end
end
