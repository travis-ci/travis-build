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
                sh.cmd "wget -q -O tmate.tar.xz #{static_build_linux_url}", echo: false, retry: true
                sh.cmd "tar --strip-components=1 -xf tmate.tar.xz", echo: false
              end
              sh.else do
                sh.echo "We are setting up the debug environment. This may take a while..."
                sh.cmd "brew update &> /dev/null", echo: false, retry: true
                sh.cmd "brew install tmate &> /dev/null", echo: false, retry: true
              end
            end

            sh.file "travis_debug.sh", bash('travis_debug', encode: true), decode: true
            sh.chmod '+x', "travis_debug.sh", echo: false

            sh.mkdir "${TRAVIS_HOME}/.ssh", echo: false, recursive: true
            sh.cmd "cat /dev/zero | ssh-keygen -q -f ${TRAVIS_HOME}/.ssh/tmate -N '' &> /dev/null", echo: false
            sh.file "${TRAVIS_HOME}/.tmate.conf", template("tmate.conf.erb", identity: "${TRAVIS_HOME}/.ssh/tmate")

            sh.export 'PATH', "${PATH}:#{install_dir}", echo: false

            sh.cd :back, echo: false, stack: true
          sh.raw '}'

          sh.raw 'function travis_debug() {'
            sh.cmd 'rm ${TRAVIS_HOME}/.netrc'
            sh.raw 'travis_debug_install'
            sh.echo "Preparing debug sessions."
            sh.raw 'TRAVIS_CMD=travis_debug'
            sh.raw 'export TRAVIS_DEBUG_MODE=true'
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
            "${TRAVIS_HOME}/.debug"
          end

          # XXX the following does not apply to OSX
          def static_build_linux_url
            if config[:arch] == 'arm64'
              "https://#{app_host}/files/tmate-static-linux-arm64v8.tar.xz"
            else
              "https://#{app_host}/files/tmate-static-linux-amd64.tar.xz"
            end
          end
      end
    end
  end
end
