require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ShellSessionUpdate < Base
        def apply
          sh.cmd <<~EOF
            if [ "$TRAVIS_OS_NAME" = osx ] && ! declare -f shell_session_update >/dev/null; then
              shell_session_update() { :; }
              export -f shell_session_update
            fi
          EOF
        end
      end
    end
  end
end
