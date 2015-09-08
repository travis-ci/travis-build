require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Firefox < Base
        SUPER_USER_SAFE = true

        def after_prepare
          sh.fold 'install_firefox' do
            unless version
              sh.echo "Invalid version '#{raw_version}' given.", ansi: :red
              return
            end

            export_source_url
            sh.echo "Installing Firefox #{version}", ansi: :yellow
            sh.mkdir install_dir, echo: false, recursive: true
            sh.chown 'travis', install_dir, recursive: true
            sh.cd install_dir, echo: false, stack: true
            sh.if 'z$FIREFOX_SOURCE_URL == "z"' do
              sh.echo "Unable to find Firefox #{version}"
            end
            sh.else do
              sh.echo "Found Firefox $FIREFOX_SOURCE_URL"
              sh.cmd "wget -O /tmp/#{filename} $FIREFOX_SOURCE_URL", echo: true, timing: true, retry: true
              sh.cmd "tar xf /tmp/#{filename}"
              sh.cmd "sudo ln -sf #{install_dir}/firefox/firefox /usr/local/bin/firefox", echo: false
              sh.cd :back, echo: false, stack: true
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

          def export_source_url
            host = 'releases.mozilla.org'
            path = "pub/firefox/releases/#{version}/linux-x86_64/en-US/"
            if version.include? 'latest'
              sh.export 'FIREFOX_SOURCE_URL', "http://#{host}/#{path}$(curl -o- -s http://#{host}/#{path} | grep -o -E 'firefox-[0-9]+(\.[0-9]+)+(b[0-9]|esr)?\.tar\.bz2' | head -1)"
            else
              sh.export 'FIREFOX_SOURCE_URL', "http://#{host}/#{path}#{filename}"
            end
          end

          def tmp_file
            '/tmp/firefox.tar.bz2'
          end
      end
    end
  end
end
