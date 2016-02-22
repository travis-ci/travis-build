require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Debug < Base
        SUPER_USER_SAFE = true
        TEMPLATES_PATH = File.expand_path('templates', __FILE__.sub('.rb', ''))

        def before_prepare
          sh.fold 'install_debug' do
            sh.echo "Setting up debug tools", ansi: :yellow

            sh.mkdir install_dir, echo: false, recursive: true
            sh.cd install_dir, echo: false, stack: true

            sh.if "$(uname) = 'Linux'" do
              sh.cmd "wget -q -O tmate.tar.gz #{static_build_linux_url}", echo: true, timing: true, retry: true
              sh.cmd "tar --strip-components=1 -xf tmate.tar.gz", echo: false
              sh.cmd "sudo ln -sf #{install_dir}/tmate /usr/local/bin/", echo: false
            end
            sh.else do
              sh.cmd "brew update", echo: true, timing: true, retry: true
              sh.cmd "brew install tmate", echo: true, timing: true, retry: true
            end

            sh.file "travis_debug", template('travis_debug.sh')
            sh.chmod '+x', "travis_debug", echo: false
            sh.cmd "sudo ln -sf #{install_dir}/travis_debug /usr/local/bin/", echo: false
            sh.cmd "unset -f travis_debug" # unset funtion in header.sh

            sh.cmd "cat /dev/zero | ssh-keygen -q -N ''", echo: false

            sh.cd :back, echo: false, stack: true
          end
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
