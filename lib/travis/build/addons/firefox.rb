require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Firefox < Base
        SUPER_USER_SAFE = true
        WGET_FLAGS = ' --no-verbose'

        attr_reader :version, :latest

        def after_prepare
          @version, @latest = sanitize_version

          unless version
            sh.echo "Invalid version '#{raw_version}' given. Skipping Firefox installation.", ansi: :red
            return
          end

          sh.fold 'install_firefox' do
            sh.echo "Installing Firefox #{version}", ansi: :yellow
            export_source_url
            sh.mkdir install_dir, echo: false, recursive: true
            sh.chown 'travis', install_dir, recursive: true
            sh.cd install_dir, echo: false, stack: true
            sh.if '$(uname) = "Linux"' do
              sh.cmd "wget#{WGET_FLAGS} -O /tmp/#{filename} $FIREFOX_SOURCE_URL", echo: true, timing: true, retry: true
              sh.cmd "tar xf /tmp/#{filename}"
              sh.export 'PATH', "#{install_dir}/firefox:$PATH"
            end
            sh.elif '$(uname) = "Darwin"' do
              sh.cmd "wget#{WGET_FLAGS} -O /tmp/#{filename('dmg')} $FIREFOX_SOURCE_URL", echo: true, timing: true, retry: true
              sh.cmd "hdiutil mount -readonly -mountpoint firefox /tmp/#{filename('dmg')}"
              sh.cmd "sudo rm -rf '/Applications/#{mac_app_name}.app'"
              sh.cmd "sudo cp -a 'firefox/#{mac_app_name}.app' /Applications"
              sh.cmd "sudo ln -sf '/Applications/#{mac_app_name}.app/Contents/MacOS/firefox' /usr/local/bin/firefox", echo: false
              sh.cmd "hdiutil unmount firefox && rm /tmp/#{filename('dmg')}"
              sh.export 'PATH', "/Applications/#{Shellwords.escape(mac_app_name)}.app/Contents/MacOS:$PATH"
            end
            sh.cd :back, echo: false, stack: true
          end
          sh.cmd "firefox --version", echo: true
        end

        private
          def raw_version
            config.to_s.strip.shellescape
          end

          def sanitize_version
            if m = /\A(?<version>[\d\.]+(?:esr|b\d+)?|(?<latest>latest(?:-(?:beta|dev|esr|nightly|unsigned))?)?)\z/.match(raw_version.chomp)
              [m[:version], m[:latest]]
            end
          end

          def install_dir
            "${TRAVIS_HOME}/firefox-#{version}"
          end

          def filename(ext = 'tar.bz2')
            "firefox-#{version}.#{ext}"
          end

          def export_source_url
            host = 'download.mozilla.org'

            case latest

            when 'latest'
              product = 'firefox-latest'
            when 'latest-beta'
              product = 'firefox-beta-latest'
            when 'latest-esr'
              product = 'firefox-esr-latest'
            when 'latest-dev'
              product = 'firefox-devedition-latest'
            when 'latest-nightly'
              product = 'firefox-nightly-latest'
            when 'latest-unsigned'
              host = 'index.taskcluster.net'
              path = "v1/task/gecko.v2.mozilla-release.latest.firefox.%s-add-on-devel/artifacts/public/build"
              unsigned_archive_file = "target.%s"
              source_url_linux = "\"https://#{host}/#{path}/#{unsigned_archive_file}\""
              source_url_mac   = "\"https://#{host}/#{path}/#{unsigned_archive_file}\""
            else
              product = "firefox-#{version}"
            end

            sh.if "$(uname) = 'Linux'" do
              source_url_linux ||= "'https://#{host}/?product=#{product}&lang=en-US&os=linux64'"
              sh.export 'FIREFOX_SOURCE_URL', source_url_linux % [ "linux64", "tar.bz2" ]
            end
            sh.else do
              source_url_mac ||= "'https://#{host}/?product=#{product}&lang=en-US&os=osx'"
              sh.export 'FIREFOX_SOURCE_URL', source_url_mac % ["macosx64", "dmg" ]
            end
          end

          def mac_app_name
            case latest
            when 'latest-dev'
              'Firefox Developer Edition'
            when 'latest-nightly'
              'Firefox Nightly'
            when 'latest-unsigned'
              'Nightly'
            else
              'Firefox'
            end
          end

          def tmp_file
            '/tmp/firefox.tar.bz2'
          end
      end
    end
  end
end
