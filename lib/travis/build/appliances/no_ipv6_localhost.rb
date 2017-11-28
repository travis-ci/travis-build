require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class NoIpv6Localhost < Base
        def apply
          sh.raw %(sed -e 's/^\\([0-9a-f:]\\+\\s\\)localhost/\\1/' /etc/hosts > /tmp/hosts.tmp && sudo sh -c 'cat /tmp/hosts.tmp >/etc/hosts')
        end
      end
    end
  end
end
