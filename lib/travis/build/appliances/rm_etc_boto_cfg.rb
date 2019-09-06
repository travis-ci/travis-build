require 'travis/build/appliances/base'
require 'travis/build/git'

module Travis
  module Build
    module Appliances
      class RmEtcBotoCfg < Base
        def apply
          sh.cmd "rm -f /etc/boto.cfg", sudo: true, assert: false, echo: false
        end

        def apply?
          !windows?
        end
      end
    end
  end
end
