require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixHhvmSource < Base
        def apply
          command = <<-EOF
            if command -v lsb_release; then
              grep -l -i -r hhvm /etc/apt/sources.list.d | xargs sudo rm -f
              sudo sed -i /hhvm/d /etc/apt/sources.list
              if [[ $(lsb_release -cs) = trusty ]]; then
                sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94
                sudo add-apt-repository "deb [arch=amd64] https://dl.hhvm.com/ubuntu $(lsb_release -sc) main"
              fi
            fi &>/dev/null
          EOF
          sh.cmd command, assert: false
        end
      end
    end
  end
end
