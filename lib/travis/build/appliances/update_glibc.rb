require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateGlibc < Base
        def apply
          sh.fold "fix.CVE-2015-7547" do
            fix_gce_apt_src
            sh.export 'DEBIAN_FRONTEND', 'noninteractive'
            sh.cmd <<-EOF
if [ ! $(uname|grep Darwin) ]; then
  sudo -E apt-get -yq update 2>&1 >> ~/apt-get-update.log
  sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install libc6
fi
            EOF
          end
        end

        def fix_gce_apt_src
          sh.if "`hostname` == testing-gce-*" do
            sh.cmd "sudo sed -i 's%us-central1.gce.archive.ubuntu.com/ubuntu%us.archive.ubuntu.com/ubuntu%' /etc/apt/sources.list"
          end
        end
      end
    end
  end
end

