require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {}

        include Jdk

        def setup
          super

          # Set Android SDK environment variables and export them
          set_android_environment_variables

          if build_tools_desired.empty?
            sh.echo "No build-tools version specified in android.components. Consider adding one of the following:", ansi: :yellow
            sh.cmd "sdkmanager --list | grep 'build-tools' | cut -d'|' -f1", echo: false, timing: false
            sh.echo "The following versions are preinstalled:", ansi: :yellow
            sh.cmd "for v in $(ls #{android_sdk_build_tools_dir} | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false
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
            # Determine Android SDK home
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            sh.export 'ANDROID_HOME', android_home
            
            # Set path to sdkmanager based on specified structure
            sdkmanager_path = "#{android_home}/android-sdk/cmdline-tools/latest/cmdline-tools/bin"
            
            # Add paths to PATH
            sh.export 'PATH', "#{sdkmanager_path}:#{android_home}/android-sdk/tools:#{android_home}/android-sdk/tools/bin:#{android_home}/android-sdk/platform-tools:$PATH"
            
            # Create directory structure if it doesn't exist
            sh.cmd "mkdir -p #{sdkmanager_path}", echo: false
          end

          def install_sdk_components
            sh.fold 'android.install' do
              sh.echo 'Installing Android dependencies'
              
              # Accepting licenses preemptively - required for non-interactive installation
              sh.cmd 'yes | sdkmanager --licenses >/dev/null || true', echo: true
              
              components.each do |name|
                sh.cmd install_sdk_component(name)
              end
            end
          end

          def install_sdk_component(name)
            # Convert name from format "build-tools-31.0.0" to "build-tools;31.0.0" for sdkmanager
            sdk_name = if name =~ /^build-tools-(.+)$/
                         "build-tools;#{$1}"
                       elsif name =~ /^platform-tools-(.+)$/
                         "platform-tools"
                       elsif name =~ /^tools-(.+)$/
                         "tools"
                       elsif name =~ /^platforms-android-(.+)$/
                         "platforms;android-#{$1}"
                       elsif name =~ /^system-images-android-(.+)-(.+)-(.+)$/
                         "system-images;android-#{$1};#{$2};#{$3}"
                       else
                         name
                       end
            
            "sdkmanager '#{sdk_name}' --verbose"
          end

          def build_tools_desired
            components.map do |component|
              if component =~ /^build-tools-(?<version>[\d\.]+)$/
                Regexp.last_match[:version]
              end
            end.compact
          end

          def android_sdk_build_tools_dir
            # Get build-tools directory based on ANDROID_HOME with nested android-sdk directory
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            File.join(android_home, 'android-sdk', 'build-tools')
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
