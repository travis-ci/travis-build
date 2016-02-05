require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSshRoaming < Base
        def apply
          sh.cmd %(mkdir -p $HOME/.ssh)
          sh.cmd %(chmod 0700 $HOME/.ssh)
          sh.cmd %(touch $HOME/.ssh/config)
          sh.cmd %(echo -e "Host *\n  UseRoaming no\n" | cat - $HOME/.ssh/config > $HOME/.ssh/config.tmp && mv $HOME/.ssh/config.tmp $HOME/.ssh/config)
        end
      end
    end
  end
end
