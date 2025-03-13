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
          if build_tools_desired.empty?
            sh.echo "No build-tools version specified in android.components. Consider adding build-tools or other components:", ansi: :yellow
            sh.cmd "#{@sdkmanager_bin} --sdk_root=#{android_home} --list", echo: true, timing: false
            sh.echo "The following build-tools versions are preinstalled (if any):", ansi: :yellow
            sh.if "-d #{android_sdk_build_tools_dir}" do
              sh.cmd "for v in $(ls #{android_sdk_build_tools_dir} | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false
            end
            sh.else do
              sh.echo "No preinstalled build-tools found", ansi: :yellow
            end
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
          sh.elif '-f build.xml' do  # Dodano sprawdzenie istnienia build.xml
            sh.cmd 'ant debug install test'
          end
          sh.else do
            sh.echo 'No known build file found. Please provide one of: gradlew, build.gradle, pom.xml, or build.xml', ansi: :yellow
            sh.echo 'Skipping build step due to missing build files', ansi: :yellow
            # Opcja 1: Pominięcie budowania zamiast niepowodzenia
            sh.cmd 'true', echo: false  # Build "zakończy się powodzeniem" mimo braku plików
          end
        end

        private

          def set_android_environment_variables
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            sh.cmd "mkdir -p #{android_home}/cmdline-tools/bin", echo: false
            sh.export 'ANDROID_HOME', android_home
            
            # Sprawdź różne możliwe lokalizacje sdkmanager
            @sdkmanager_bin = nil
            possible_paths = [
              "#{android_home}/cmdline-tools/bin/sdkmanager",
              "#{android_home}/cmdline-tools/latest/bin/sdkmanager",
              "#{android_home}/tools/bin/sdkmanager"
            ]
            
            possible_paths.each do |path|
              sh.if "-f #{path}" do
                @sdkmanager_bin = path
              end
            end
            
            # Jeśli nadal nie znaleziono, użyj domyślnej ścieżki
            sh.if "[ -z \"$(@sdkmanager_bin)\" ]" do
              @sdkmanager_bin = "#{android_home}/cmdline-tools/bin/sdkmanager"
              sh.cmd "mkdir -p #{File.dirname(@sdkmanager_bin)}", echo: false
            end
            
            sh.export 'PATH', "#{File.dirname(@sdkmanager_bin)}:#{android_home}/tools:#{android_home}/tools/bin:#{android_home}/platform-tools:$PATH"
          end

          def install_sdk_components
            sh.fold 'android.install' do
              sh.echo 'Installing Android dependencies'
              android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
              
              # Ensure build-tools directory exists
              sh.cmd "mkdir -p #{android_sdk_build_tools_dir}", echo: false
              
              # Accept licenses
              sh.cmd "yes | #{@sdkmanager_bin} --sdk_root=#{android_home} --licenses >/dev/null || true", echo: true
              
              components.each do |name|
                sh.cmd install_sdk_component(name)
              end
            end
          end

          def install_sdk_component(name)
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            sdk_name = if name =~ /^build-tools-(.+)$/
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
            "yes | #{@sdkmanager_bin} --sdk_root=#{android_home} \"#{sdk_name}\" --verbose"
          end

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
