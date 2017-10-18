require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RmRiakSource < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            sudo rm -f /etc/apt/sources.list.d/basho_riak.list
          fi
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end
