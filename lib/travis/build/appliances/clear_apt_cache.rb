require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ClearAptCache < Base
        def apply
          sh.cmd <<-EOF
            ls /var/lib/apt/lists/packagecloud.io* >/dev/null && (
              sudo rm -rf /var/lib/apt/lists/packagecloud.io*
              sudo apt-get update -qq
            )
          EOF
        end
      end
    end
  end
end
