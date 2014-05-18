module Travis
  module Build
    class Script
      module Addons
        class Firefox
          REQUIRES_SUPER_USER = true

          def initialize(script, config)
            @script = script
            @firefox_version = config.to_s
          end

          def before_install
            @script.fold('install_firefox') do |script|
              script.cmd "echo -e \"\033[33;1mInstalling Firefox v#{@firefox_version}\033[0m\"; ", assert: false, echo: false
              script.cmd "sudo mkdir -p /usr/local/firefox-#{@firefox_version}", assert: false
              script.cmd "sudo chown -R travis /usr/local/firefox-#{@firefox_version}", assert: false
              script.cmd "wget -O /tmp/firefox.tar.bz2 http://ftp.mozilla.org/pub/firefox/releases/#{@firefox_version}/linux-x86_64/en-US/firefox-#{@firefox_version}.tar.bz2", assert: false
              script.cmd "pushd /usr/local/firefox-#{@firefox_version}", assert: false
              script.cmd "tar xf /tmp/firefox.tar.bz2", assert: false
              script.cmd "sudo ln -sf /usr/local/firefox-#{@firefox_version}/firefox/firefox /usr/local/bin/firefox", assert: false
              script.cmd "sudo ln -sf /usr/local/firefox-#{@firefox_version}/firefox/firefox-bin /usr/local/bin/firefox-bin", assert: false
              script.cmd "popd", assert: false
            end
          end
        end
      end
    end
  end
end

