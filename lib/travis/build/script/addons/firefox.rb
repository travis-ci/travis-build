module Travis
  module Build
    class Script
      module Addons
        class Firefox
          def initialize(script, config)
            @script = script
            @firefox_version = config.to_s
          end

          def before_install
            @script.fold('install_firefox') do |script|
              script.cmd "echo -e \"\033[33;1mInstalling Firefox v#@firefox_version\033[0m\"; ", assert: false, echo: false
              script.cmd 'pushd', assert: false
              script.cmd "mkdir -p /tmp/firefox_install", assert: false
              script.cmd "cd /tmp/firefox_install", assert: false
              script.cmd "wget ftp://ftp.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-#@firefox_version.tar.bz2", assert: false
              script.cmd "tar xf firefox-#@firefox_version.tar.bz2", assert: false
              script.cmd "sudo ln -s /tmp/firefox_install/firefox/firefox /usr/local/bin/firefox", assert: false
              script.cmd 'popd', assert: false
            end
          end
        end
      end
    end
  end
end

