require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {}

        include Jdk

        def setup
          super
          
          android_home = '/usr/local/android-sdk'
          sh.echo "Using Android SDK at #{android_home}", ansi: :green
          sh.export 'ANDROID_HOME', android_home, echo: true
          
          sh.echo "Setting up sdkmanager", ansi: :green
          
          # Najpierw sprawdzamy, czy sdkmanager jest dostępny w PATH
          sdkmanager_path = nil
          sdkmanager_cmd = nil
          
          sh.cmd "command -v sdkmanager >/dev/null && echo \"FOUND_IN_PATH=YES\" || echo \"FOUND_IN_PATH=NO\"", echo: false, assert: true do |result|
            if result.stdout.include?("FOUND_IN_PATH=YES")
              sh.echo "sdkmanager available in PATH", ansi: :green
              sdkmanager_cmd = "sdkmanager --sdk_root=\"#{android_home}\""
            else
              sh.echo "sdkmanager not available in PATH, checking specific locations", ansi: :yellow
              
              # Sprawdzamy konkretną ścieżkę, którą widzimy w logach
              sdkmanager_path = "#{android_home}/cmdline-tools/bin/sdkmanager"
              
              sh.cmd "test -f \"#{sdkmanager_path}\" && echo \"FOUND=YES\" || echo \"FOUND=NO\"", echo: false, assert: true do |path_result|
                if path_result.stdout.include?("FOUND=YES")
                  sh.echo "Found sdkmanager at #{sdkmanager_path}", ansi: :green
                  sdkmanager_cmd = "\"#{sdkmanager_path}\" --sdk_root=\"#{android_home}\""
                else
                  sdkmanager_path = nil
                  sh.echo "sdkmanager not found at expected location", ansi: :yellow
                end
              end
            end
          end
          
          # Jeśli nadal nie mamy sdkmanager, dodajemy narzędzia Android do PATH
          if sdkmanager_cmd.nil?
            sh.echo "Trying to add Android tools to PATH", ansi: :yellow
            sh.export 'PATH', "#{android_home}/cmdline-tools/bin:#{android_home}/tools/bin:#{android_home}/platform-tools:$PATH", echo: true
            
            sh.cmd "command -v sdkmanager >/dev/null && echo \"NOW_FOUND=YES\" || echo \"NOW_FOUND=NO\"", echo: false, assert: true do |result|
              if result.stdout.include?("NOW_FOUND=YES")
                sh.echo "sdkmanager now available in PATH after adjustment", ansi: :green
                sdkmanager_cmd = "sdkmanager --sdk_root=\"#{android_home}\""
              else
                sh.echo "sdkmanager still not available in PATH", ansi: :red
              end
            end
          end
          
          # Używamy komendy sdkmanager, jeśli jest dostępna
          if sdkmanager_cmd
            sh.echo "Using sdkmanager command: #{sdkmanager_cmd}", ansi: :green
            
            if build_tools_desired.empty?
              sh.echo "No build-tools version specified in android.components. Available versions:", ansi: :yellow
              sh.cmd "#{sdkmanager_cmd} --list | grep 'build-tools' | cut -d'|' -f1 || echo 'Failed to list build-tools'", echo: true, assert: true
              
              sh.echo "Preinstalled versions:", ansi: :yellow
              sh.cmd "ls -la #{android_sdk_build_tools_dir} 2>/dev/null || echo 'None'", echo: true, assert: true
            end
            
            unless components.empty?
              sh.echo "Installing Android components: #{components.join(', ')}", ansi: :green
              
              sh.echo "Accepting SDK licenses"
              sh.cmd "yes | #{sdkmanager_cmd} --licenses > /dev/null || echo 'License acceptance failed'", echo: true, assert: true
              
              components.each do |name|
                sh.echo "Installing component: #{name}", ansi: :yellow
                
                sdk_name = if name =~ /^build-tools-(.+)$/
                  "build-tools;#{$1}"
                elsif name == 'platform-tools'
                  "platform-tools"
                elsif name == 'tools'
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
                
                sh.cmd "yes | #{sdkmanager_cmd} \"#{sdk_name}\" --verbose || echo 'Installation of #{name} failed'", echo: true, assert: true
              end
            end
          else
            sh.echo "Could not find sdkmanager, Android build may fail", ansi: :red
          end
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

          def build_tools_desired
            components.map do |component|
              if component =~ /^build-tools-(?<version>[\d\.]+)$/
                Regexp.last_match[:version]
              end
            end.compact
          end

          def android_sdk_build_tools_dir
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            File.join(android_home, 'build-tools')
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
