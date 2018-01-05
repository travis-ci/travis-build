require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateMongodb32Key < Base
        def apply
          sh.if "$(command -v lsb_release)" do
            sh.cmd 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 42F3E95A2C4F08279C4960ADD68FA50FEA312927', echo: false, assert: false, sudo: true
          end
        end
      end
    end
  end
end
