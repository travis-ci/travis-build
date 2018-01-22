require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableSudo < Base
        WRITE_SUDO = <<-EOC
cat <<-'EOF' > _sudo
#!/bin/bash
if [[ -f \$HOME/.sudo-run ]]; then
  exit 1
fi

OPTIND=1
while getopts "v" opt; do
  case $opt in
  v)
    QUIET=1
    ;;
  esac
done

shift "$((OPTIND-1))"

if [[ $QUIET != 1 ]]; then
echo -e "\\\\033[33;1mThis job is running on container-based infrastructure, which does not allow use of 'sudo', setuid, and setgid executables.\\\\033[0m
\\\\033[33;1mIf you require sudo, add 'sudo: required' to your .travis.yml\\\\033[0m
"
fi

touch \$HOME/.sudo-run

exit 1
EOF
        EOC
        CLEANUP = 'sudo -n sh -c "chmod 4755 _sudo; chown root:root _sudo; mv _sudo `which sudo`; find / \\( -perm -4000 -o -perm -2000 \\) -a ! -name sudo -exec chmod a-s {} \; 2>/dev/null && sed -e \'s/^%.*//\' -i.bak /etc/sudoers && rm -f /etc/sudoers.d/travis"'

        def apply
          sh.raw WRITE_SUDO
          sh.cmd CLEANUP
        end

        def apply?
          data.disable_sudo?
        end
      end
    end
  end
end
