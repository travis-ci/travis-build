require 'travis/build/script/appliances/base'

module Travis
  module Build
    class Script
      module Appliances
        class FixEtcHosts < Base
          def apply
            sh.cmd %(sudo sed -e 's/^\\(127\\.0\\.0\\.1.*\\)$/\\1 '`hostname`'/' -i'.bak' /etc/hosts)
          end

          def apply?
            data[:fix_etc_hosts] || !data[:skip_etc_hosts_fix]
          end
        end
      end
    end
  end
end
