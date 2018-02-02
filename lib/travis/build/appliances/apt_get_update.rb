require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt-get update --option Acquire::Retries="5" --option Acquire::http::Timeout="30"
          fi
          EOF
          sh.cmd command
        end
      end
    end
  end
end
