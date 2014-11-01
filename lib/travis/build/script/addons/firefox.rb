require 'shellwords'
require 'travis/build/script/addons/base'

module Travis
  module Build
    class Script
      class Addons
        class Firefox < Base
          SUPER_USER_SAFE = false

          def before_prepare
            sh.fold 'install_firefox' do
              sh.echo "Installing Firefox v#{version}", ansi: :yellow
              sh.mkdir install_dir, echo: false, recursive: true, sudo: true
              sh.chown 'travis', install_dir, recursive: true, sudo: true
              sh.cmd "wget -O /tmp/firefox.tar.bz2 #{source_url}", retry: true
              sh.cd install_dir, stack: true, echo: false
              sh.cmd "tar xf /tmp/firefox.tar.bz2"
              sh.cd :back, stack: true, echo: false
              sh.cmd "ln -sf #{install_dir}/firefox/firefox /usr/local/bin/firefox", sudo: true
              sh.cmd "ln -sf #{install_dir}/firefox/firefox-bin /usr/local/bin/firefox-bin", sudo: true
            end
          end

          private

            def version
              config.shellescape
            end

            def install_dir
              "/usr/local/firefox-#{version}"
            end

            def source_url
              "http://releases.mozilla.org/pub/firefox/releases/#{version}/linux-x86_64/en-US/firefox-#{version}.tar.bz2"
            end

            def tmp_file
              '/tmp/firefox.tar.bz2'
            end
        end
      end
    end
  end
end
