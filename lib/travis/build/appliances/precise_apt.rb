require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class PreciseApt < Base
        def apply
          sh.if "-f /etc/apt/sources.list && $(lsb_release -cs) = precise" do
            sh.cmd "sudo sed -i -re 's:/([a-z]{2}\.)?archive.ubuntu.com|/security.ubuntu.com:/old-releases.ubuntu.com:g' /etc/apt/sources.list", echo: false
          end
        end
      end
    end
  end
end
