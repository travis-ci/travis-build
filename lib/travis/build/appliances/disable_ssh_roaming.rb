require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSshRoaming < Base
        def apply
          sh.cmd %(echo -e "Host *\n  UseRoaming no\n" | cat - $HOME/.ssh/config > $HOME/.ssh/config.tmp && mv $HOME/.ssh/config.tmp $HOME/.ssh/config)
        end
      end
    end
  end
end
