require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt-get update -qq 2>&1 >/dev/null
          fi
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end
