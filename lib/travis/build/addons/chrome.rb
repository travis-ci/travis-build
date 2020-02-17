require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Chrome < Base
        SUPER_USER_SAFE = true
        WGET_FLAGS = ' --no-verbose'

        attr_reader :version

        def after_prepare
          sh.fold 'install_chrome' do
            @version ||= sanitize_version

            unless version
              sh.echo "Invalid version '#{raw_version}' given.", ansi: :red
            end

            export_source_url
            sh.echo "Installing Google Chrome #{version}", ansi: :yellow

            sh.if '$(uname) = "Linux"' do
              sh.if "$(lsb_release -cs) = 'precise'" do
                sh.echo "Google Chrome addon is not supported on Precise", ansi: :yellow
              end
              sh.else do
                sh.cmd "wget#{WGET_FLAGS} -O /tmp/$(basename $CHROME_SOURCE_URL) $CHROME_SOURCE_URL", echo: true, timing: true, retry: true
                sh.cmd "sudo dpkg -i /tmp/$(basename $CHROME_SOURCE_URL)"
              end
            end
            sh.elif '$(uname) = "Darwin"' do
              sh.cmd "wget#{WGET_FLAGS} -O /tmp/$(basename $CHROME_SOURCE_URL) $CHROME_SOURCE_URL", echo: true, timing: true, retry: true
              sh.cmd "hdiutil mount -readonly -mountpoint chrome /tmp/$(basename $CHROME_SOURCE_URL)"
              sh.cmd "sudo rm -rf /Applications/Google\\ Chrome.app"
              sh.cmd "sudo cp -a chrome/Google\\ Chrome.app /Applications"
              sh.cmd "hdiutil unmount chrome && rm /tmp/$(basename $CHROME_SOURCE_URL)"
            end
            sh.cd :back, echo: false, stack: true
          end
        end

        private
          def raw_version
            config.to_s.strip.shellescape
          end

          def sanitize_version
            if m = /\A(?<version>stable|beta)\z/.match(raw_version.chomp)
              m[:version]
            end
          end

          def export_source_url
            sh.if "$(uname) = 'Linux'" do
              pkg_url = "https://dl.google.com/dl/linux/direct/google-chrome-#{version}_current_amd64.deb"
              sh.export 'CHROME_SOURCE_URL', pkg_url
            end
            sh.elif "$(uname) = 'Darwin'" do
              case version
              when 'stable'
                pkg_url = "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"
              when 'beta'
                pkg_url = "https://dl.google.com/chrome/mac/beta/googlechrome.dmg"
              end
              sh.export 'CHROME_SOURCE_URL', pkg_url
            end
          end
      end
    end
  end
end
