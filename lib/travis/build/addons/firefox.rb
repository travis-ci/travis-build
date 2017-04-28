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
            end

            export_source_url
            sh.echo "Installing Firefox #{version}", ansi: :yellow
            sh.mkdir install_dir, echo: false, recursive: true
            sh.chown 'travis', install_dir, recursive: true
            sh.cd install_dir, echo: false, stack: true
            sh.if '$(uname) = "Linux"' do
              sh.cmd "wget -O /tmp/#{filename} $FIREFOX_SOURCE_URL", echo: true, timing: true, retry: true
              sh.cmd "tar xf /tmp/#{filename}"
              sh.export 'PATH', "#{install_dir}/firefox:$PATH"
            end
            sh.elif '$(uname) = "Darwin"' do
              sh.cmd "wget -O /tmp/#{filename('dmg')} $FIREFOX_SOURCE_URL", echo: true, timing: true, retry: true
              sh.cmd "hdiutil mount -readonly -mountpoint firefox /tmp/#{filename('dmg')}"
              sh.cmd "sudo rm -rf /Applications/Firefox.app"
              sh.cmd "sudo cp -a firefox/Firefox.app /Applications"
              sh.cmd "sudo ln -sf /Applications/Firefox.app/Contents/MacOS/firefox /usr/local/bin/firefox", echo: false
              sh.cmd "hdiutil unmount firefox && rm /tmp/#{filename('dmg')}"
              sh.export 'PATH', "/Applications/Firefox.app/Contents/MacOS:$PATH"
            end
            sh.cd :back, echo: false, stack: true
          end
        end

        private
          def raw_version
            config.to_s.strip.shellescape
          end

          def sanitize(input)
            if m = /\A(?<version>[\d\.]+(?:esr|b\d+)?|(?<latest>latest(?:-(?:beta|dev|esr|nightly|unsigned))?)?)\z/.match(input.chomp)
              @version = m[:version]
              @latest  = m[:latest]
            end
          end

          def install_dir
            "#{HOME_DIR}/firefox-#{version}"
          end

          def filename(ext = 'bz2')
            "firefox-#{version}.tar.#{ext}"
          end

          def export_source_url
            host = 'download.mozilla.org'

            product = case latest

            when 'latest'
              'firefox-latest'
            when 'latest-beta'
              'firefox-beta-latest'
            when 'latest-esr'
              'firefox-esr-latest'
            when 'latest-dev'
              # The name 'aurora' is nickname for "developer edition",
              # documented in https://wiki.mozilla.org/Firefox/Channels#Developer_Edition_.28aka_Aurora.29
              # This may change in the future and break builds.
              'firefox-aurora-latest'
            when 'latest-nightly'
              'firefox-nightly-latest'
            when 'latest-unsigned'
              host = 'index.taskcluster.net'
              path = "v1/task/gecko.v2.mozilla-release.latest.firefox.%s-add-on-devel/artifacts/public/build"
              unsigned_archive_file = "firefox-%s.en-US.%s-add-on-devel.%s"
              source_url = "\"https://#{host}/#{path}/#{unsigned_archive_file}\""
            else
              "firefox-#{version}"
            end

            sh.if "$(uname) = 'Linux'" do
              source_url ||= "'https://#{host}/?product=#{product}&lang=en-US&os=linux64'"
              sh.export 'FIREFOX_SOURCE_URL', source_url % [ "linux64", "$(curl -sfL https://#{host}/#{path}/buildbot_properties.json | jq -r .properties.appVersion)" % "linux64", "linux-x86_64", "tar.bz2" ]
            end
            sh.else do
              source_url ||= "'https://#{host}/?product=#{product}&lang=en-US&os=osx'"
              sh.export 'FIREFOX_SOURCE_URL', source_url % ["macosx64", "$(curl -sfL https://#{host}/#{path}/buildbot_properties.json | jq -r .properties.appVersion)" % "macosx64", "mac", "dmg" ]
            end
          end

          def tmp_file
            '/tmp/firefox.tar.bz2'
          end
      end
    end
  end
end
