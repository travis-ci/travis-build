module Travis
  module Build
    class Script
      module Addons
        class Hosts
          REQUIRES_SUPER_USER = true

          def initialize(script, config)
            @script = script
            @config = [config].flatten
          end

          def setup
            @script.fold("hosts") do |script|
              script.cmd("sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 #{@config.join(' ')}/' -i'.bak' /etc/hosts")
              script.cmd("sudo sed -e 's/^\\(::1.*\\)$/\\1 #{@config.join(' ')}/' -i'.bak' /etc/hosts")
            end
          end
        end
      end
    end
  end
end
