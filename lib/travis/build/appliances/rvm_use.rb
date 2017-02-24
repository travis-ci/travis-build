require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RvmUse < Base
        def apply
          sh.if "$(command -v sw_vers)" do
            sh.cmd "rvm use", echo: true
          end
        end
      end
    end
  end
end
