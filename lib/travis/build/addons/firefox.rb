require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Firefox < Base
        SUPER_USER_SAFE = true

        def after_prepare
          sh.fold 'install_firefox' do
            if version
              sh.echo "Installing Firefox v#{version}", ansi: :yellow
              sh.mkdir install_dir, echo: false, recursive: true
              sh.chown 'travis', install_dir, recursive: true
              sh.cd install_dir, echo: false, stack: true
              sh.cmd "wget -O /tmp/#{filename} #{source_url}", echo: true, timing: true, retry: true
              sh.cmd "tar xf /tmp/#{filename}"
              sh.cmd "sudo ln -sf #{install_dir}/firefox/firefox /usr/local/bin/firefox", echo: false
              sh.cd :back, echo: false, stack: true
            else
              sh.echo "Invalid version '#{raw_version}' given.", ansi: :red
            end
          end
        end

        private

          def version
            sanitize raw_version
          end

          def raw_version
            config.to_s.strip.shellescape
          end

          def sanitize(input)
            (m = /\A(?<version>[\d\.]+(?:esr)?|latest(?:-(?:beta|esr))?)\z/.match(input.chomp)) && m[:version]
          end

          def install_dir
            "#{HOME_DIR}/firefox-#{version}"
          end

          def filename
            "firefox-#{version}.tar.bz2"
          end

          def source_url
            "http://releases.mozilla.org/pub/firefox/releases/#{version}/linux-x86_64/en-US/#{filename}"
          end

          def tmp_file
            '/tmp/firefox.tar.bz2'
          end
      end
    end
  end
end
