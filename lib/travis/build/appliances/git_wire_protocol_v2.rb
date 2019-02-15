require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class GitWireProtocolV2 < Base
        def apply
          sh.cmd "git config --global protocol.version 2", assert: false, echo: false
        end
      end
    end
  end
end
