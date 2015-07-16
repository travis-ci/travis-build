require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixResolvConf < Base
        def apply
          resolv_conf_data = <<-EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
          EOF

          sh.raw %(echo "#{resolv_conf_data}" | sudo tee /etc/resolv.conf &> /dev/null)
        end

        def apply?
          if data.key?(:fix_resolv_conf)
            data[:fix_resolv_conf]
          else
            !data[:skip_resolv_updates]
          end
        end
      end
    end
  end
end
