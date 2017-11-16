
require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixHhvmSource < Base
        def apply
          sh.if "$(command -v lsb_release)" do
            command = <<-EOF
            if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
              grep -l -i -r hhvm /etc/apt/sources.list.d | xargs sudo rm -vf
            fi
            EOF
            sh.cmd command, echo: false
            sh.cmd "apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94", echo: false, assert: false, sudo: true
            sh.cmd "add-apt-repository 'deb [ arch=amd64 ] http://dl.hhvm.com/ubuntu $(lsb_release -sc) main'", echo: false, assert: false, sudo: true
          end
        end
      end
    end
  end
end