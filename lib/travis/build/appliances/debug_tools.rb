require 'shellwords'
require 'travis/build/appliances/base'
require 'travis/build/helpers/template'

module Travis
  module Build
    module Appliances
      class DebugTools < Base
        include Template
        TEMPLATES_PATH = File.expand_path('templates', __FILE__.sub('.rb', ''))

        def enabled?
          return true
          ENV['ENABLE_TRAVIS_DEBUG'] == '1'
        end

        def apply
          enabled? ? apply_enabled : apply_disabled
        end

        def apply_enabled
          sh.raw 'function travis_debug_install() {'
            sh.mkdir install_dir, echo: false, recursive: true
            sh.cd install_dir, echo: false, stack: true

            sh.if "$(uname) = 'Linux'" do
              sh.cmd "wget -q -O tmate.tar.gz #{static_build_linux_url}", echo: false, retry: true
              sh.cmd "tar --strip-components=1 -xf tmate.tar.gz", echo: false
            end
            sh.else do
              sh.cmd "brew update", echo: false, retry: true
              sh.cmd "brew install tmate", echo: false, retry: true
            end

            sh.file "travis_debug.sh", template('travis_debug.sh')
            sh.chmod '+x', "travis_debug.sh", echo: false

            sh.cmd "cat /dev/zero | ssh-keygen -q -N '' &> /dev/null", echo: false

            sh.export 'PATH', "${PATH}:#{install_dir}", echo: false

            sh.cd :back, echo: false, stack: true
          sh.raw '}'

          sh.raw 'function travis_debug() {'
            sh.raw 'travis_debug_install'
            sh.cmd 'travis_debug.sh', stack: true
          sh.raw '}'
        end

        def apply_disabled
          sh.raw 'function travis_debug() {'
            sh.echo "The debug environement is not available. Please contact support.", ansi: :red
            sh.raw "false"
          sh.raw '}'
        end

        private
          def install_dir
            "#{HOME_DIR}/.debug"
          end

          # XXX the following does not apply to OSX

          def version
            "2.2.0"
          end

          def static_build_linux_url
            "https://github.com/tmate-io/tmate/releases/download/#{version}/tmate-#{version}-static-linux-amd64.tar.gz"
          end
      end
    end
  end
end
