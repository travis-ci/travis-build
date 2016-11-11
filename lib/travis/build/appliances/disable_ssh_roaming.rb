require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSshRoaming < Base
        def apply
          sh.cmd <<-EOF
if [ $(sw_vers -productVersion | cut -d . -f 2) -lt 12 ]; do
  mkdir -p $HOME/.ssh
  chmod 0700 $HOME/.ssh
  touch $HOME/.ssh/config
  echo -e "Host *\n  UseRoaming no\n" | cat - $HOME/.ssh/config > $HOME/.ssh/config.tmp && mv $HOME/.ssh/config.tmp $HOME/.ssh/config
fi
          EOF
        end
      end
    end
  end
end
