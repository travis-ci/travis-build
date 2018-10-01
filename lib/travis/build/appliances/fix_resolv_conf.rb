require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixResolvConf < Base
        def apply
          current_resolv_conf = File.read('/etc/resolv.conf')
          resolv_conf_data = <<-EOF
options rotate
options timeout:1

nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 208.67.222.222
nameserver 208.67.220.220
          EOF

          if current_resolv_conf =~ /nameserver\s+199\.91\.168/
            resolv_conf_data << "\nnameserver 199.91.168.70\nnameserver 199.91.168.71\n"
          end
          sh.raw %(echo "#{resolv_conf_data}" | sudo tee /etc/resolv.conf &> /dev/null)
        end

        def apply?
          return unless super
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
