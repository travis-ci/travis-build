require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Firefox < Base
        SUPER_USER_SAFE = true

        attr_reader :version, :latest

        def after_prepare
          sh.fold 'install_firefox' do
            sanitize(raw_version)

            unless version
              sh.echo "Invalid version '#{raw_version}' given.", ansi: :red
              return
            end

            export_source_url
            sh.echo "Installing Firefox #{version}", ansi: :yellow
            sh.mkdir install_dir, echo: false, recursive: true
            sh.chown 'travis', install_dir, recursive: true
            sh.cd install_dir, echo: false, stack: true
            sh.cmd "wget -O /tmp/#{filename} $FIREFOX_SOURCE_URL", echo: true, timing: true, retry: true
            sh.cmd "tar xf /tmp/#{filename}"
            sh.cmd "sudo ln -sf #{install_dir}/firefox/firefox /usr/local/bin/firefox", echo: false
            sh.cd :back, echo: false, stack: true
          end
        end

        private
          def raw_version
            config.to_s.strip.shellescape
          end

          def sanitize(input)
            if m = /\A(?<version>[\d\.]+(?:esr)?|(?<latest>latest(?:-(?:beta|esr))?)?)\z/.match(input.chomp)
              @version = m[:version]
              @latest  = m[:latest]
            end
          end

          def install_dir
            "#{HOME_DIR}/firefox-#{version}"
          end

          def filename
            "firefox-#{version}.tar.bz2"
          end

          def export_source_url
            product = case latest
            when 'latest'
              'firefox-latest'
            when 'latest-beta'
              'firefox-beta-latest'
            when 'latest-esr'
              'firefox-esr-latest'
            else
              "firefox-#{version}"
            end

            host = 'download.mozilla.org'

            sh.if "$(uname) = 'Linux'" do
              sh.export 'FIREFOX_SOURCE_URL', "'https://#{host}/?product=#{product}&lang=en-US&os=linux64'"
            end
            sh.else do
              sh.export 'FIREFOX_SOURCE_URL', "'https://#{host}/?product=#{product}&lang=en-US&os=osx'"
            end
          end

          def tmp_file
            '/tmp/firefox.tar.bz2'
          end
      end
    end
  end
end
