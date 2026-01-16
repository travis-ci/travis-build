require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class NonblockPipe < Base

        def apply
          command = <<-EOF
if [[ $TRAVIS_FILTERED = redirect_io ]]; then
  cat <<\\EOPY >~/nonblock.py
import os
import sys
import fcntl

flags_stdout = fcntl.fcntl(sys.stdout, fcntl.F_GETFL)
fcntl.fcntl(sys.stdout, fcntl.F_SETFL, flags_stdout&~os.O_NONBLOCK)

flags_stderr = fcntl.fcntl(sys.stderr, fcntl.F_GETFL)
fcntl.fcntl(sys.stderr, fcntl.F_SETFL, flags_stderr&~os.O_NONBLOCK)
EOPY
  python3 ~/nonblock.py
  rm ~/nonblock.py
fi
EOF

          sh.cmd command
        end

      end
    end
  end
end
