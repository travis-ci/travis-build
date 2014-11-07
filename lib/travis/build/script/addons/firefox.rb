module Travis
  module Build
    class Script
      module Addons
        class Firefox
          SUPER_USER_SAFE = true

          def initialize(script, config)
            @script = script
            @firefox_version = config.to_s
          end

          def before_install
            @script.fold 'install_firefox' do |sh|
              sh.echo "Installing Firefox v#{@firefox_version}", ansi: :yellow
              sh.raw "mkdir -p \$HOME/firefox-#{@firefox_version}"
              sh.raw "chown -R travis \$HOME/firefox-#{@firefox_version}"
              sh.cmd "wget -O /tmp/firefox.tar.bz2 http://releases.mozilla.org/pub/firefox/releases/#{@firefox_version}/linux-x86_64/en-US/firefox-#{@firefox_version}.tar.bz2", retry: true
              sh.raw "pushd \$HOME/firefox-#{@firefox_version}"
              sh.raw "tar xf /tmp/firefox.tar.bz2"
              sh.raw "export PATH=\$HOME/firefox-#{@firefox_version}/firefox:\$PATH"
              sh.raw "popd"
            end
          end
        end
      end
    end
  end
end
