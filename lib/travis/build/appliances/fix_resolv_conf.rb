require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixResolvConf < Base
        def apply
          sh.cmd %(grep '199.91.168' /etc/resolv.conf > /dev/null || echo 'nameserver 199.91.168.70\nnameserver 199.91.168.71' | sudo tee /etc/resolv.conf &> /dev/null)
        end

        def apply?
          data[:fix_resolv_conf] || !data[:skip_resolv_updates]
        end
      end
    end
  end
end
