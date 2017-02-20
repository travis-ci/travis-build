require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ClearAptCache < Base
        def apply
          sh.cmd <<-EOF
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt-get update -qq
          EOF
        end
      end
    end
  end
end
