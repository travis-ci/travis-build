require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateGlibc < Base
        def apply
          sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
          sh.cmd <<--EOF
if [ ! $(uname|grep Darwin) ]; then
  sudo -E apt-get -yq update &>> ~/apt-get-update.log"
  sudo -E apt-get -yq --no-install-suggests --no-install-recommends "--force-yes install libc6"
fi
          EOF
        end
      end
    end
  end
end

