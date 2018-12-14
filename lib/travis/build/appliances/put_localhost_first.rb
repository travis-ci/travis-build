require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class PutLocalhostFirst < Base
        def apply
          # gather names mapped to 127.0.0.1
          sh.raw %q(grep '^127\.0\.0\.1' /etc/hosts | sed -e 's/^127\.0\.0\.1\\s\\{1,\\}\\(.*\\)/\1/g' | sed -e 's/localhost \\(.*\\)/\1/g' | tr "\n" " " > /tmp/hosts_127_0_0_1)
          # remove lines with 127.0.0.1
          sh.raw %q(sed '/^127\.0\.0\.1/d' /etc/hosts > /tmp/hosts_sans_127_0_0_1)
          # reconstruct /etc/hosts
          sh.raw %q(cat /tmp/hosts_sans_127_0_0_1 | sudo tee /etc/hosts > /dev/null)
          sh.raw %q(echo -n "127.0.0.1 localhost " | sudo tee -a /etc/hosts > /dev/null)
          sh.raw %q({ cat /tmp/hosts_127_0_0_1; echo; } | sudo tee -a /etc/hosts > /dev/null)
        end
      end
    end
  end
end
