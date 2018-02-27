require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateOsxOpenssl < Base
        def apply
          sh.cmd <<-EOF
if [ $(command -v sw_vers) ]; then
  echo "Brew updating openssl"
	brew update && brew upgrade openssl
fi
          EOF
        end
      end
    end
  end
end
