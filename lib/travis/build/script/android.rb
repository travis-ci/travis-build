require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {}

        include Jdk

        def setup
          super

          # Set up Android SDK environment
          set_up_android_sdk

          if build_tools_desired.empty?
            sh.echo "No build-tools version specified in android.components. Consider adding one of the following:", ansi: :yellow
            sh.cmd "for v in $(ls #{android_sdk_build_tools_dir} 2>/dev/null || echo); do echo build-tools-$v; done", echo: false, timing: false
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

          def set_up_android_sdk
            sh.fold 'android.setup' do
              sh.echo 'Setting up Android SDK'
              
              # Define paths
              sh.export 'ANDROID_HOME', '/usr/local/android-sdk'
              sh.export 'ANDROID_SDK_ROOT', '/usr/local/android-sdk/android-sdk'
              
              # Create necessary directories with proper permissions
              sh.cmd "sudo mkdir -p $ANDROID_SDK_ROOT/licenses", echo: true
              sh.cmd "sudo mkdir -p $ANDROID_SDK_ROOT/.android", echo: true
              sh.cmd "sudo mkdir -p $HOME/.android", echo: true
              
              # Create configuration files
              sh.cmd "sudo touch $ANDROID_SDK_ROOT/.android/repositories.cfg", echo: true
              sh.cmd "sudo touch $HOME/.android/repositories.cfg", echo: true
              
              # Set permissions
              sh.cmd "sudo chmod -R 777 $ANDROID_SDK_ROOT", echo: true
              sh.cmd "sudo chmod -R 777 $HOME/.android", echo: true
              
              # Accept licenses by creating license files with known license hashes
              sh.cmd "echo '24333f8a63b6825ea9c5514f83c2829b004d1fee' | sudo tee $ANDROID_SDK_ROOT/licenses/android-sdk-license > /dev/null", echo: true
              sh.cmd "echo '84831b9409646a918e30573bab4c9c91346d8abd' | sudo tee $ANDROID_SDK_ROOT/licenses/android-sdk-preview-license > /dev/null", echo: true
              
              # Add cmdline-tools to PATH
              cmdline_tools_bin = "$ANDROID_SDK_ROOT/cmdline-tools/latest/cmdline-tools/bin"
              sh.cmd "[ -d \"#{cmdline_tools_bin}\" ] || sudo mkdir -p #{cmdline_tools_bin}", echo: true
              sh.export 'PATH', "#{cmdline_tools_bin}:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
            end
          end

          def install_sdk_components
            sh.fold 'android.install' do
              sh.echo 'Installing Android dependencies'
              
              # Install each component individually with error handling
              components.each do |name|
                component_name = convert_component_name(name)
                
                sh.echo "Installing #{component_name}", ansi: :yellow
                
                # Use a simple, direct command to avoid complex shell expression issues
                sh.cmd "yes | sudo -E ANDROID_HOME=$ANDROID_SDK_ROOT sdkmanager --sdk_root=$ANDROID_SDK_ROOT '#{component_name}' || true", echo: true
                
                # Verify installation
                sh.cmd "sdkmanager --list | grep -q '#{component_name}' || echo 'Warning: Installation of #{component_name} may have failed'", echo: true
              end
            end
          end

          def convert_component_name(name)
            # Convert name from format "build-tools-31.0.0" to "build-tools;31.0.0" for sdkmanager
            if name =~ /^build-tools-(.+)$/
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
          end

          def build_tools_desired
            components.map do |component|
              if component =~ /^build-tools-(?<version>[\d\.]+)$/
                Regexp.last_match[:version]
              end
            end.compact
          end

          def android_sdk_build_tools_dir
            '/usr/local/android-sdk/android-sdk/build-tools'
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
