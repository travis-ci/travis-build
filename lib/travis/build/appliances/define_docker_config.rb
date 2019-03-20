require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DefineDockerConfig < Base
        def apply
          sh.raw %(echo '{ "registry-mirrors": ["https://mirror.gcr.io"] }' | sudo tee /etc/docker/daemon.json > /dev/null 2>&1)
        end
      end
    end
  end
end
