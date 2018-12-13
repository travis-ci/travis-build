require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class NoIpv6Localhost < Base
        def apply
          sh.echo 'Before NoIpv6Localhost'
          sh.raw 'cat /etc/hosts'
          sh.raw %(sed -e 's/^\\([0-9a-f:]\\+\\s\\)localhost/\\1/' /etc/hosts > /tmp/hosts.tmp && cat /tmp/hosts.tmp | sudo tee /etc/hosts > /dev/null 2>&1)
          sh.echo 'After NoIpv6Localhost'
          sh.raw 'cat /etc/hosts'
        end
      end
    end
  end
end
