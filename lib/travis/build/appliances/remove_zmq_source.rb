require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RemoveZmqSource < Base
        def apply
          sh.raw %(sudo rm -f /etc/apt/sources.list.d/travis_ci_zeromq3-source.list)
        end
      end
    end
  end
end
