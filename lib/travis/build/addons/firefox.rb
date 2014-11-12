require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Firefox < Base
        SUPER_USER_SAFE = true

        def before_setup
          sh.fold 'install_firefox' do
            sh.echo "Installing Firefox v#{version}", ansi: :yellow
            sh.raw "mkdir -p #{HOME_DIR}/firefox-#{version}"
            sh.raw "chown -R travis #{HOME_DIR}/firefox-#{version}"
            sh.cmd "wget -O /tmp/firefox.tar.bz2 http://releases.mozilla.org/pub/firefox/releases/#{version}/linux-x86_64/en-US/firefox-#{version}.tar.bz2", assert: true, echo: true, timing: true, retry: true
            sh.raw "pushd #{HOME_DIR}/firefox-#{version}"
            sh.raw "tar xf /tmp/firefox.tar.bz2"
            sh.raw "export PATH=#{HOME_DIR}/firefox-#{version}/firefox:\$PATH"
            sh.raw "popd"
            # sh.mkdir install_dir, echo: false, recursive: true, sudo: true, cmd: true
            # sh.chown 'travis', install_dir, recursive: true, sudo: true, cmd: true
            # sh.cmd "wget -O /tmp/firefox.tar.bz2 #{source_url}", assert: false, echo: true, timing: true, retry: true
            # sh.cd install_dir, stack: true, echo: false
            # sh.cmd "tar xf /tmp/firefox.tar.bz2"
            # sh.cd :back, stack: true, echo: false
            # sh.cmd "ln -sf #{install_dir}/firefox/firefox /usr/local/bin/firefox", sudo: true
            # sh.cmd "ln -sf #{install_dir}/firefox/firefox-bin /usr/local/bin/firefox-bin", sudo: true
          end
        end

        private

          def version
            config.to_s.gsub(/[^\d\._\-]/, '').shellescape
          end

          def install_dir
            "#{HOME_DIR}/firefox-#{version}"
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
