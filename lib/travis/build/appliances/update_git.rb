require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateGit < Base
        def apply?
          !Travis::Build.config.update_git.empty?
        end

        def apply
          sh.fold "fix.update-git" do
            sh.cmd <<-EOF
if [ ! $(uname|grep Darwin) ]; then
  DEBIAN_FRONTEND=noninteractive sudo -E add-apt-repository -y ppa:git-core/ppa
  DEBIAN_FRONTEND=noninteractive sudo -E apt-get -yq update 2>&1 >> ~/apt-get-update.log
  DEBIAN_FRONTEND=noninteractive sudo -E apt-get -yq --no-install-suggests --no-install-recommends --force-yes install git
fi
            EOF
          end
        end
      end
    end
  end
end
