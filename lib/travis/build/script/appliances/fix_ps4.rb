require 'travis/build/script/appliances/base'

module Travis
  module Build
    class Script
      module Appliances
        class FixPs4 < Base
          def apply
            sh.export "PS4", "+ ", echo: false
          end
        end
      end
    end
  end
end
