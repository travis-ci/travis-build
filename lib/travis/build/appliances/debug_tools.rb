require 'shellwords'
require 'travis/build/appliances/base'
require 'travis/build/helpers/template'

module Travis
  module Build
    module Appliances
      class DebugTools < Base
        include Template
        TEMPLATES_PATH = File.expand_path('templates', __FILE__.sub('.rb', ''))

        def_delegators :script, :debug_enabled?, :debug_build_via_api?

        def apply
          (debug_enabled? || debug_build_via_api?) ? apply_enabled : apply_disabled
        end

        def apply_enabled
          sh.raw 'function travis_debug_install() {'
            sh.echo "Setting up debug tools.", ansi: :yellow
            sh.mkdir install_dir, echo: false, recursive: true
            sh.cd install_dir, echo: false, stack: true

            sh.if "-z $(command -v tmate)" do
              sh.if "$(uname) = 'Linux'" do
                sh.cmd "wget -q -O tmate.tar.gz #{static_build_linux_url}", echo: false, retry: true
                sh.cmd "tar --strip-components=1 -xf tmate.tar.gz", echo: false
              end
              sh.else do
                sh.echo "We are setting up the debug environment. This may take a while..."
                sh.cmd "brew update &> /dev/null", echo: false, retry: true
                sh.cmd "brew install tmate &> /dev/null", echo: false, retry: true
              end
            end

            sh.file "travis_debug.sh", template('travis_debug.sh')
            sh.chmod '+x', "travis_debug.sh", echo: false

            sh.mkdir "#{HOME_DIR}/.ssh", echo: false, recursive: true
            sh.cmd "cat /dev/zero | ssh-keygen -q -f #{HOME_DIR}/.ssh/tmate -N '' &> /dev/null", echo: false
            sh.file "#{HOME_DIR}/.tmate.conf", template("tmate.conf", identity: "#{HOME_DIR}/.ssh/tmate")

            sh.export 'PATH', "${PATH}:#{install_dir}", echo: false

            sh.cd :back, echo: false, stack: true
          sh.raw '}'

          sh.raw 'function travis_debug() {'
            sh.raw 'travis_debug_install'
            sh.echo "Preparing debug sessions."
            sh.raw 'TRAVIS_CMD=travis_debug'
            sh.raw 'travis_debug.sh "$@"'
          sh.raw '}'
        end

        def apply_disabled
          sh.raw 'function travis_debug() {'
            sh.echo "The debug environment is not available. Please contact support.", ansi: :red
            sh.raw "false"
          sh.raw '}'
        end

        private
          def install_dir
            "#{HOME_DIR}/.debug"
          end

          # XXX the following does not apply to OSX
          def static_build_linux_url
            "https://#{app_host}/files/tmate-static-linux-amd64.tar.gz"
          end
      end
    end
  end
end
