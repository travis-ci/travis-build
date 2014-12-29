require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class PutLocalhostFirst < Base
        def apply
          sh.cmd "sudo sed -e 's/^127\\.0\\.0\\.1\\(.*\\) localhost \\(.*\\)$/127.0.0.1 localhost \\1 \\2/' -i'.bak' /etc/hosts 2>/dev/null"
        end
      end
    end
  end
end
