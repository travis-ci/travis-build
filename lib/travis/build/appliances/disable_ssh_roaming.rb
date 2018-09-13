require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSshRoaming < Base
        def apply
          sh.raw bash('travis_disable_ssh_roaming')
          sh.if %("$(sw_vers -productVersion 2>/dev/null | cut -d . -f 2)" -lt 12) do
            sh.cmd 'travis_disable_ssh_roaming'
          end
        end
      end
    end
  end
end
