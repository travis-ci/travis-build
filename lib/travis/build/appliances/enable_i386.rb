require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class EnableI386 < Base
        def apply
          sh.if "$(uname -m) == x86_64 && $(command -v lsb_release) && $(lsb_release -cs) != precise && $(lsb_release -cs) != Ootpa"  do
            sh.cmd 'dpkg --add-architecture i386', echo: false, assert: false, sudo: true
          end
        end
      end
    end
  end
end
