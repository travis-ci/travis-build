module Travis
  module Build
    class Script
      module Addons
        class Firefox
          SUPER_USER_SAFE = false

          def initialize(script, config)
            @script = script
            @firefox_version = config.to_s
          end

          def before_install
            @script.fold 'install_firefox' do |sh|
              sh.echo "Installing Firefox v#{@firefox_version}", ansi: :yellow
              sh.raw "sudo mkdir -p /usr/local/firefox-#{@firefox_version}"
              sh.raw "sudo chown -R travis /usr/local/firefox-#{@firefox_version}"
              sh.cmd "wget -O /tmp/firefox.tar.bz2 http://ftp.mozilla.org/pub/firefox/releases/#{@firefox_version}/linux-x86_64/en-US/firefox-#{@firefox_version}.tar.bz2", retry: true
              sh.raw "pushd /usr/local/firefox-#{@firefox_version}"
              sh.raw "tar xf /tmp/firefox.tar.bz2"
              sh.raw "sudo ln -sf /usr/local/firefox-#{@firefox_version}/firefox/firefox /usr/local/bin/firefox"
              sh.raw "sudo ln -sf /usr/local/firefox-#{@firefox_version}/firefox/firefox-bin /usr/local/bin/firefox-bin"
              sh.raw "popd"
            end
          end
        end
      end
    end
  end
end
