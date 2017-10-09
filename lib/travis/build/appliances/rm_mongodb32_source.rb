require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RmMongodb32Source < Base
        def apply
          sh.if "$(command -v lsb_release)" do
            sh.cmd 'rm -f /etc/apt/sources.list.d/mongodb-3.2.list', echo: false, assert: false, sudo: true
          end
        end
      end
    end
  end
end
