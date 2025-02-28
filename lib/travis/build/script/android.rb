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
              
              # Automatically accept all licenses - create a script to handle this
              sh.echo 'Setting up license acceptance script'
              sh.cmd "mkdir -p /tmp/android-sdk-licenses"
              sh.cmd "cat > /tmp/android-sdk-licenses/accept-licenses.sh << 'EOL'
#!/bin/bash
set -e
count=0
while [ $count -lt 100 ]; do
  sleep 1
  if [ $(ps -ef | grep sdkmanager | grep -v grep | wc -l) -eq 0 ]; then
    break
  fi
  output=$(ps -ef | grep 'Accept? (y/N)' | grep -v grep || true)
  if [ ! -z \"$output\" ]; then
    echo y | sdkmanager --sdk_root=#{android_home}/android-sdk --licenses >/dev/null
    count=0
  else
    count=$((count+1))
  fi
done
EOL"
              sh.cmd "chmod +x /tmp/android-sdk-licenses/accept-licenses.sh"
              
              # First, try to accept all licenses up front
              sh.cmd "echo y | sdkmanager --sdk_root=#{android_home}/android-sdk --licenses >/dev/null || true"
              
              # Start the license acceptance script in the background
              sh.cmd "/tmp/android-sdk-licenses/accept-licenses.sh &"
              
              # Install each component
              components.each do |name|
                sh.cmd install_sdk_component(name)
                # Give time for any license prompts to be handled by the background script
                sh.cmd "sleep 2"
              end
              
              # Kill the license acceptance script if it's still running
              sh.cmd "pkill -f accept-licenses.sh || true"
            end
          end

          def install_sdk_component(name)
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            
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
            
            # Auto-accept any license prompt that may appear during installation
            "yes | sdkmanager --sdk_root=#{android_home}/android-sdk '#{sdk_name}' --verbose"
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
