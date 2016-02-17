require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateGlibc < Base
        def apply
          sh.export 'DEBIAN_FRONTEND', 'noninteractive', echo: true
          sh.cmd "sudo -E apt-get -yq update &>> ~/apt-get-update.log", echo: true, timing: true
          sh.cmd 'sudo -E apt-get -yq --no-install-suggests --no-install-recommends ' \
                "--force-yes install libc6}", echo: true, timing: true
        end
      end
    end
  end
end

