require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RvmUse < Base
        def apply
          sh.if "$(command -v sw_vers)" do
            sh.cmd "rvm use &>/dev/null", echo: false
          end
        end
      end
    end
  end
end
