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

          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          
          if build_tools_desired.empty?
            sh.echo "No build-tools version specified in android.components. Consider adding one of the following:", ansi: :yellow
            sh.cmd "sdkmanager --sdk_root=#{android_home}/android-sdk --list | grep 'build-tools' | cut -d'|' -f1", echo: false, timing: false
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
            sdk_root = "#{android_home}/android-sdk"
            sdkmanager_path = "#{sdk_root}/cmdline-tools/latest/cmdline-tools/bin"
            
            # Add paths to PATH
            sh.export 'PATH', "#{sdkmanager_path}:#{sdk_root}/tools:#{sdk_root}/tools/bin:#{sdk_root}/platform-tools:$PATH"

            # Create necessary directories and set permissions
            sh.cmd "mkdir -p #{sdk_root}", echo: false
            sh.cmd "mkdir -p #{sdk_root}/licenses", echo: false
            sh.cmd "mkdir -p #{sdk_root}/.android", echo: false
            
            # Create necessary property files
            sh.cmd "touch #{sdk_root}/.android/repositories.cfg", echo: false
            
            # Set proper permissions
            sh.cmd "chmod -R 755 #{sdk_root}", echo: false
            sh.cmd "chmod -R 777 #{sdk_root}/.android", echo: false
            sh.cmd "chmod -R 777 #{sdk_root}/licenses", echo: false
            
            # Create standard license files to bypass some checks
            sh.cmd "echo '24333f8a63b6825ea9c5514f83c2829b004d1fee' > #{sdk_root}/licenses/android-sdk-license", echo: false
            sh.cmd "echo '84831b9409646a918e30573bab4c9c91346d8abd' > #{sdk_root}/licenses/android-sdk-preview-license", echo: false
          end
          end

          def install_sdk_components
            sh.fold 'android.install' do
              sh.echo 'Installing Android dependencies'
              
              android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
              sdk_root = "#{android_home}/android-sdk"
              
              # Ensure SDK directories exist with proper permissions
              sh.cmd "mkdir -p #{sdk_root}/licenses", echo: true
              sh.cmd "mkdir -p #{sdk_root}/.android", echo: true
              sh.cmd "touch #{sdk_root}/.android/repositories.cfg", echo: true
              sh.cmd "chmod -R 777 #{sdk_root}/.android", echo: true
              sh.cmd "chmod -R 777 #{sdk_root}/licenses", echo: true
              
              # Create license acceptance files (these are the standard license hashes)
              sh.cmd "echo '24333f8a63b6825ea9c5514f83c2829b004d1fee' > #{sdk_root}/licenses/android-sdk-license", echo: true
              sh.cmd "echo '84831b9409646a918e30573bab4c9c91346d8abd' > #{sdk_root}/licenses/android-sdk-preview-license", echo: true
              
              # Add all known license agreements to bypass interactive prompts
              sh.cmd "mkdir -p #{sdk_root}/licenses", echo: false
              sh.cmd "echo '24333f8a63b6825ea9c5514f83c2829b004d1fee' > #{sdk_root}/licenses/android-sdk-license", echo: false
              sh.cmd "echo '84831b9409646a918e30573bab4c9c91346d8abd' > #{sdk_root}/licenses/android-sdk-preview-license", echo: false
              sh.cmd "echo 'd975f751698a77b662f1254ddbeed3901e976f5a' > #{sdk_root}/licenses/intel-android-extra-license", echo: false
              sh.cmd "echo '8933bad161af4178b1185d1a37fbf41ea5269c55' > #{sdk_root}/licenses/android-googletv-license", echo: false
              sh.cmd "echo '33b6a2b64607f11b759f320ef9dff4ae5c47d97a' > #{sdk_root}/licenses/google-gdk-license", echo: false
              
              # Install each component
              components.each do |name|
                sh.cmd install_sdk_component(name)
              end
            end
          end

          def install_sdk_component(name)
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            sdk_root = "#{android_home}/android-sdk"
            
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
            
            # More robust command with environment variables and error handling
            "mkdir -p #{sdk_root}/.android && " +
            "touch #{sdk_root}/.android/repositories.cfg && " +
            "JAVA_OPTS='-Duser.home=#{sdk_root}' " +
            "ANDROID_SDK_HOME='#{sdk_root}' " +
            "echo y | sdkmanager --sdk_root='#{sdk_root}' '#{sdk_name}' --verbose || " +
            "echo 'Retrying installation...' && " +
            "JAVA_OPTS='-Duser.home=#{sdk_root}' " +
            "ANDROID_SDK_HOME='#{sdk_root}' " +
            "echo y | sdkmanager --sdk_root='#{sdk_root}' '#{sdk_name}' --verbose"
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
