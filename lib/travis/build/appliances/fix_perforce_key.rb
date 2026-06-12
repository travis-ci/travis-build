require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixPerforceKey < Base
        def apply
          sh.if "! $(command -v sw_vers)" do
            sh.cmd "wget --tries=1 --timeout=10 -qO - https://package.perforce.com/perforce.pubkey | sudo apt-key add - || true", assert: false, echo: false
          end
        end
      end
    end
  end
end
