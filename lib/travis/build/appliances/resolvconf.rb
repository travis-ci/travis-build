require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Resolvconf < Base
        def apply?
          linux?
        end

        def apply
          sh.fold "resolvconf" do
            sh.raw <<-EOF
echo "options timeout:5"  | sudo tee -a /etc/resolvconf/resolv.conf.d/tail >/dev/null
echo "options attempts:5" | sudo tee -a /etc/resolvconf/resolv.conf.d/tail >/dev/null
sudo service resolvconf restart
            EOF
          end
        end
      end
    end
  end
end
