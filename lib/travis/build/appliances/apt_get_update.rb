require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt update --option ForceIPv4=1 --option Debug::Acquire::http=1 --option Debug::Acquire::https=1 --option Debug::pkgAcquire::Worker=1 --option Debug::pkgDPkgPM=1 --option Debug::RunScripts=1 --option Acquire::Retries="5" --option Acquire::http::Timeout="30"
          fi
          EOF
          sh.cmd command
        end
      end
    end
  end
end
