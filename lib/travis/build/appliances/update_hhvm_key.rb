
require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateHhvmKey < Base
        def apply
          sh.if "$(command -v lsb_release)" do
            sh.cmd 'apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94', echo: false, assert: false, sudo: true
          end
        end
      end
    end
  end
end