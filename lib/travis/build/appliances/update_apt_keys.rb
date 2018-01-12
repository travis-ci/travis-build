require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateAptKeys < Base
        def apply
          command = <<-EOF
          if command -v apt-get && [[ -d /var/lib/apt/lists ]]; then
            LANG=C apt-key list | awk -F'[ /]+' '/expired:/{printf "apt-key adv --recv-keys --keyserver keys.gnupg.net %s\\n", $3}' | sudo sh &>/dev/null
          fi
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end

