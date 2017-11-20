require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class NoIpv6Localhost < Base
        def apply
          sh.raw %(sudo sed -e 's/^\\([0-9a-f:]\\+\\s\\)localhost\\(.*\\)/\\1 /' -i'.bak' /etc/hosts)
        end

        def apply?
          ! data.disable_sudo?
        end
      end
    end
  end
end
