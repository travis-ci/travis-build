require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Resolvconf < Base
        def apply?
          linux?
        end

        def apply
          sh.if 'sudo service resolvconf status >&/dev/null', raw: true do
            sh.fold "resolvconf" do
              sh.raw <<-EOF
  echo "options timeout:1"  | sudo tee -a /etc/resolvconf/resolv.conf.d/tail >/dev/null
  echo "options attempts:3" | sudo tee -a /etc/resolvconf/resolv.conf.d/tail >/dev/null
  sudo service resolvconf restart
              EOF
            end
          end
        end
      end
    end
  end
end
