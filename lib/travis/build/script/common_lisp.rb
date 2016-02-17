require 'tempfile'

module Travis
  module Build
    class Script
      class CommonLisp < Script
        DEFAULTS = {
          lisp: 'sbcl'
        }

        ROS_URL = "https://raw.githubusercontent.com/roswell/roswell/release/scripts/install-for-ci.sh"

        SYSTEM_MISSING = %Q[\
No test script provided.
Please either override the script: key
]

        def configure
          super
          sh.cmd 'sudo apt-get update'
          sh.cmd 'sudo apt-get -y install libc6:i386 libc6-dev libc6-dev-i386 libffi-dev libffi-dev:i386'
          sh.fold('roswell-install') do
            sh.echo "Installing roswell..."
            sh.export "LISP", lisp_impl
            sh.cmd "curl -sL #{ROS_URL} | /bin/sh"
          end
        end

        def export
          super
          sh.export 'LISP', lisp_impl
        end

        def announce
          super
          sh.cmd 'ros version'
          sh.cmd %Q[\
ros -e '(format t "~A: ~A~%" (lisp-implementation-type) (lisp-implementation-version))'
]
        end

        def script
          sh.failure SYSTEM_MISSING
        end

        private

        def lisp_impl
          config[:lisp]
        end

      end
    end
  end
end
