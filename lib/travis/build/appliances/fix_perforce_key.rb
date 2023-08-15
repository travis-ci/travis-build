require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixPerforceKey < Base
        def apply
          sh.if "! $(command -v sw_vers)" do
            sh.cmd "wget -qO - https://package.perforce.com/perforce.pubkey | sudo apt-key add -", assert: false, echo: false
          end
        end
      end
    end
  end
end
