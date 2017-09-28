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

echo -e "\\\\033[33;1mThis job is running on container-based infrastructure, which does not allow use of 'sudo', setuid, and setgid executables.\\\\033[0m
\\\\033[33;1mIf you require sudo, add 'sudo: required' to your .travis.yml\\\\033[0m
"

touch \$HOME/.sudo-run

exit 1
EOF
        EOC
        CLEANUP = <<-EOC
sudo -n sh -c "
    chmod 4755 _sudo
    chown root:root _sudo
    mv _sudo `which sudo`
    set -e
    mount -o remount,nosuid /
    sed -e 's/^%.*//' -i.bak /etc/sudoers
    rm -f /etc/sudoers.d/travis
"
EOC

        def apply
          sh.raw WRITE_SUDO
          sh.cmd CLEANUP, echo: true, timing: true
        end

        def apply?
          data.disable_sudo?
        end
      end
    end
  end
end
