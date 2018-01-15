require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class NonblockPipe < Base

        def apply
          sh.cmd '[[ $TRAVIS_FILTERED = redirect_io ]] && python ~/nonblock.py'
        end

      end
    end
  end
end
