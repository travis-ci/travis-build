require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateMongodbKey < Base
        def apply
          sh.if "$(command -v lsb_release)" do
            sh.cmd "[ $(lsb_release -sc) != precise ] && [ -f /etc/apt/sources.list.d/mongodb-3.4.list ] && grep -vq arch=amd64 /etc/apt/sources.list.d/mongodb-3.4.list && sudo sed -i 's/^deb /deb [arch=amd64] /' /etc/apt/sources.list.d/mongodb-3.4.list", echo: false, assert: false, sudo: false
            sh.cmd '[ $(lsb_release -sc) != precise ] && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6', echo: false, assert: false, sudo: false
          end
        end
      end
    end
  end
end
