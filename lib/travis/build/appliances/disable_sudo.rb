require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSudo < Base
        MSG1 = "\nThis job is running on container-based infrastructure, which does not allow use of 'sudo', setuid and setguid executables.\n"
        MSG2 = "If you require sudo, add 'sudo: required' to your .travis.yml\n"
        MSG3 = "See https://docs.travis-ci.com/user/workers/container-based-infrastructure/ for details.\n"
        CMD = 'sudo -n sh -c "sed -e \'s/^%.*//\' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis && find / -perm -4000 -exec chmod a-s {} \; 2>/dev/null"'

        def apply
          sh.echo MSG1, ansi: :yellow
          sh.echo MSG2, ansi: :yellow
          sh.echo MSG3, ansi: :yellow
          sh.cmd CMD
        end

        def apply?
          data.disable_sudo?
        end
      end
    end
  end
end
