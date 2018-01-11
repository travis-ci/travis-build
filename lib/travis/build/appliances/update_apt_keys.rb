require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptKeyUpdate < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            LANG=C apt-key list | awk -F'[ /]+' '/expired:/{printf "apt-key adv --recv-keys --keyserver keys.gnupg.net %s\n", $3}' | sudo sh &>/dev/null
          fi
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end

