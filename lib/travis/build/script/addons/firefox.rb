module Travis
  module Build
    class Script
      module Addons
        class Firefox
          SUPER_USER_SAFE = false

          attr_reader :sh, :version

          def initialize(script, config)
            @sh = script.sh
            @version = config.to_s
          end

          def before_install
            sh.fold 'install_firefox' do
              sh.echo "Installing Firefox v#{version}", ansi: :green
              sh.mkdir target_path, echo: false, recursive: true, sudo: true
              sh.chown 'travis', target_path, recursive: true, sudo: true
              sh.cmd "wget -O /tmp/firefox.tar.bz2 #{source_url}", retry: true
              sh.cd target_path, stack: true, echo: false
              sh.cmd "tar xf /tmp/firefox.tar.bz2"
              sh.cd :back, stack: true, echo: false
              sh.cmd "ln -sf #{target_path}/firefox/firefox /usr/local/bin/firefox", sudo: true
              sh.cmd "ln -sf #{target_path}/firefox/firefox-bin /usr/local/bin/firefox-bin", sudo: true
            end
          end

          def target_path
            "/usr/local/firefox-#{version}"
          end

          def source_url
            "http://ftp.mozilla.org/pub/firefox/releases/#{version}/linux-x86_64/en-US/firefox-#{version}.tar.bz2"
          end
        end
      end
    end
  end
end
