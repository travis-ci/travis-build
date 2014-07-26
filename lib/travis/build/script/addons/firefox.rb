module Travis
  module Build
    class Script
      module Addons
        class Firefox
          SUPER_USER_SAFE = false

          attr_reader :sh, :version

          def initialize(sh, config)
            @sh = sh
            @version = config.to_s
          end

          def before_install
            sh.fold 'install_firefox' do
              echo "Installing Firefox v#{version}", ansi: :green
              sh.raw "sudo mkdir -p /usr/local/firefox-#{version}"
              sh.raw "sudo chown -R travis /usr/local/firefox-#{version}"
              sh.cmd "wget -O /tmp/firefox.tar.bz2 http://ftp.mozilla.org/pub/firefox/releases/#{version}/linux-x86_64/en-US/firefox-#{version}.tar.bz2", retry: true
              sh.raw "pushd /usr/local/firefox-#{version}"
              sh.raw "tar xf /tmp/firefox.tar.bz2"
              sh.raw "sudo ln -sf /usr/local/firefox-#{version}/firefox/firefox /usr/local/bin/firefox"
              sh.raw "sudo ln -sf /usr/local/firefox-#{version}/firefox/firefox-bin /usr/local/bin/firefox-bin"
              sh.raw "popd"
            end
          end
        end
      end
    end
  end
end

