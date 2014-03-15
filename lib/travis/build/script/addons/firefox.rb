module Travis
  module Build
    class Script
      module Addons
        class Firefox
          def initialize(script, config)
            @script = script
            @firefox_version = config.to_s
          end

          def before_install
            @script.fold('install_firefox') do |script|
              script.cmd "sudo #{BIN_PATH}/travis-firefox #{@firefox_version}", assert: true, echo: false
            end
          end
        end
      end
    end
  end
end

