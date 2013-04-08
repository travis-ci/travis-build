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
              script.cmd "echo -e \"\033[33;1mInstalling Firefox v20.0\033[0m\"; ", assert: false, echo: false
              script.cmd "mkdir -p ~/usr/firefox ~/bin", assert: false
              script.cmd "wget -O /tmp/firefox.tar.bz2 ftp://ftp.mozilla.org/pub/firefox/releases/20.0/linux-x86_64/en-US/firefox-20.0.tar.bz2", assert: false
              script.cmd "pushd ~/usr/firefox", assert: false
              script.cmd "tar xf /tmp/firefox.tar.bz2", assert: false
              script.cmd "sudo ln -s ~/usr/firefox/firefox ~/bin/firefox", assert: false
              script.set 'PATH', '~/bin:$PATH', echo: false, assert: false
              script.cmd "popd", assert: false
            end
          end
        end
      end
    end
  end
end

