require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          sh.cmd <<-EOF
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt-get update -qq 2>&1 >/dev/null
          EOF
        end
      end
    end
  end
end
