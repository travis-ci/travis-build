require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {}

        include Jdk

        def setup
          super
          set_android_environment_variables
          create_symlinks
          update_cmdline_tools_latest
          if build_tools_desired.empty?
            sh.echo "Installed sdkmanager version:", ansi: :yellow
            sh.cmd "#{@sdkmanager_bin} --sdk_root=#{@android_home} --version", echo: true, timing: false
          end
          install_sdk_components unless components.empty?
        end

        def script
          sh.if '-f gradlew' do
            sh.cmd './gradlew build connectedCheck'
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle build connectedCheck'
          end
          sh.elif '-f pom.xml' do
            sh.cmd 'mvn install -B', echo: true
          end
          sh.else do
            sh.cmd 'ant debug install test'
          end
        end

        private

        def set_android_environment_variables
          @android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          sh.export 'ANDROID_HOME', @android_home
          sh.export 'ANDROID_SDK_ROOT', @android_home
          new_path = "#{@android_home}/cmdline-tools/latest/bin:" \
                     "#{@android_home}/tools:" \
                     "#{@android_home}/tools/bin:" \
                     "#{@android_home}/platform-tools:" \
                     "/usr/local/cmdline-tools/bin:" \
                     "/usr/local/emulator:" \
                     "/usr/local/platform-tools:$PATH"
          sh.export 'PATH', new_path
          
          sh.cmd "sudo mkdir -p #{@android_home}/cmdline-tools/latest/bin", echo: false
          sh.cmd "if [ ! -f #{@android_home}/cmdline-tools/latest/bin/sdkmanager ]; then sudo ln -s #{@android_home}/cmdline-tools/bin/sdkmanager #{@android_home}/cmdline-tools/latest/bin/sdkmanager; fi", echo: false
        
          @sdkmanager_bin = "#{@android_home}/cmdline-tools/latest/bin/sdkmanager"
        end

        def create_symlinks
          sh.cmd "sudo ln -s #{@android_home}/cmdline-tools /usr/local/cmdline-tools", echo: false
          sh.cmd "sudo ln -s #{@android_home}/build-tools /usr/local/build-tools", echo: false
          sh.cmd "sudo ln -s #{@android_home}/emulator /usr/local/emulator", echo: false
          sh.cmd "sudo ln -s #{@android_home}/extras /usr/local/extras", echo: false
          sh.cmd "sudo ln -s #{@android_home}/platform-tools /usr/local/platform-tools", echo: false
          sh.cmd "sudo ln -s #{@android_home}/system-images /usr/local/system-images", echo: false
        end

        def update_cmdline_tools_latest
          sh.fold 'android.update_cmdline_tools_latest' do
            sh.echo 'Updating cmdline-tools latest directory'
            sh.cmd "sudo rsync -a #{@android_home}/cmdline-tools/bin/ #{@android_home}/cmdline-tools/latest/bin/"
            sh.cmd "sudo rsync -a #{@android_home}/cmdline-tools/lib/ #{@android_home}/cmdline-tools/latest/lib/"
            sh.cmd "sudo cp -n #{@android_home}/cmdline-tools/NOTICE.txt #{@android_home}/cmdline-tools/latest/"
            sh.cmd "sudo cp -n #{@android_home}/cmdline-tools/source.properties #{@android_home}/cmdline-tools/latest/"
          end
        end

        def install_sdk_components
          sh.fold 'android.install' do
            sh.echo 'Installing Android dependencies'
            sh.echo 'Accepting Android SDK licenses', ansi: :yellow
            sh.cmd "yes | #{@sdkmanager_bin} --sdk_root=#{@android_home} --licenses >/dev/null 2>&1 || true", echo: false
            components.each do |name|
              sdk_name = determine_sdk_name(name)
              sh.cmd "yes | #{@sdkmanager_bin} --sdk_root=#{@android_home} \"#{sdk_name}\" --verbose >/dev/null 2>&1 && printf \"\\033[32mComponent #{name} installed successfully\\033[0m\\n\" || printf \"\\033[31mComponent #{name} installation failed\\033[0m\\n\"", echo: false
            end
          end
        end

        def determine_sdk_name(name)
          if name =~ /^build-tools-(.+)$/
            "build-tools;#{$1}"
          elsif name =~ /^platform-tools-(.+)$/
            "platform-tools"
          elsif name =~ /^tools-(.+)$/
            "tools"
          elsif name =~ /^platforms-android-(.+)$/
            "platforms;android-#{$1}"
          elsif name =~ /^android-(.+)$/
            "platforms;android-#{$1}"
          elsif name =~ /^system-images-android-(.+)-(.+)-(.+)$/
            "system-images;android-#{$1};#{$2};#{$3}"
          elsif name =~ /^extra-google-(.+)$/
            "extras;google;#{$1}"
          elsif name =~ /^extra-android-(.+)$/
            "extras;android;#{$1}"
          else
            name
          end
        end

        def build_tools_desired
          components.map do |component|
            if component =~ /^build-tools-(?<version>[\d\.]+)$/
              Regexp.last_match[:version]
            end
          end.compact
        end

        def android_sdk_build_tools_dir
          File.join(@android_home, 'build-tools')
        end

        def components
          android_config[:components] || []
        end

        def licenses
          android_config[:licenses] || []
        end

        def android_config
          config[:android] || {}
        end
      end
    end
  end
end
