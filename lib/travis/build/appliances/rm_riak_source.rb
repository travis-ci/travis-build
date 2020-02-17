require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RmRiakSource < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            grep -l -i -r basho /etc/apt/sources.list.d | xargs sudo rm -f
          fi
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end
