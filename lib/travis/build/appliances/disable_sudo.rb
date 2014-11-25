require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSudo < Base
        MSG = "This build is running on container-based infrastructure, which does not allow use of 'sudo', setuid and setguid executables.\nSee http://docs.travis-ci.com/user/workers/container-based-infrastructure/ for details."
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
