require 'rbconfig'
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
              sh.cmd "sudo ln -sf #{install_dir}/firefox/firefox /usr/local/bin/firefox", echo: false
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
            if m = /\A(?<version>[\d\.]+(?:esr|b\d+)?|(?<latest>latest(?:-(?:beta|esr))?)?)\z/.match(input.chomp)
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
            product = case latest
            when 'latest'
              'firefox-latest'
            when 'latest-beta'
              'firefox-beta-latest'
            when 'latest-esr'
              'firefox-esr-latest'
            when 'latest-dev'
              'firefox-aurora-latest'
            when 'latest-nightly'
              if RbConfig::CONFIG['host_os'] == /linux/
                nightly = '/.+?(?=linux-x86_64)/'
              else
                nightly = '/.+?(?=mac.dmg)/'
              end
              nightly
            else
              "firefox-#{version}"
            end

            if product == /linux|mac/
              host = 'archive.mozilla.org/pub/firefox/nightly/latest-mozilla-central/'
            else
              host = 'download.mozilla.org'
            end

            sh.if "[$(uname) = 'Linux'] && [#{product} = '/linux/']" do
              sh.export 'FIREFOX_SOURCE_URL', "'https://#{host}/#{product}.linux-x6_64.tar.bz2'"
            end
            sh.elif "[$(uname) = 'Darwin'] && [#{product} = '/mac/']" do
              sh.export 'FIREFOX_SOURCE_URL', "'https://#{host}/#{product}.mac.dmg'"
            end
            sh.elif "$(uname) = 'Linux'" do
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
