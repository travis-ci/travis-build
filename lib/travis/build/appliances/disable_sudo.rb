require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSudo < Base
        MSG = "\nSudo, the FireFox addon, setuid and setgid have been disabled.\n"
        CMD = 'sudo -n sh -c "sed -e \'s/^%.*//\' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \; 2>/dev/null"'

        def apply
          sh.echo MSG, ansi: :yellow
          sh.cmd CMD
        end

        def apply?
          data.disable_sudo?
        end
      end
    end
  end
end
