module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {
          android: {}
        }

        def setup
          super

          # Set up Android environment variables
          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          sdkmanager_bin = "#{android_home}/cmdline-tools/bin/sdkmanager"
          
          # Export Android environment variables with the correct format
          sh.export 'ANDROID_HOME', android_home
          sh.export 'PATH', "#{File.dirname(sdkmanager_bin)}:#{android_home}/tools:#{android_home}/tools/bin:#{android_home}/platform-tools:$PATH"
          
          # Make sure the directory for sdkmanager exists
          sh.cmd "mkdir -p #{File.dirname(sdkmanager_bin)}", echo: false
          
          # Install components if specified
          if config[:android] && config[:android][:components]
            sh.fold 'android.install', fold_options do
              sh.echo 'Installing Android dependencies'
              sh.cmd "yes | #{sdkmanager_bin} --sdk_root=#{android_home} --licenses >/dev/null || true", echo: true
              
              config[:android][:components].each do |component|
                if component =~ /^build-tools-(.+)$/
                  sdk_name = "build-tools;#{$1}"
                elsif component =~ /^platform-tools-(.+)$/
                  sdk_name = "platform-tools"
                elsif component =~ /^tools-(.+)$/
                  sdk_name = "tools"
                elsif component =~ /^platforms-android-(.+)$/
                  sdk_name = "platforms;android-#{$1}"
                elsif component =~ /^system-images-android-(.+)-(.+)-(.+)$/
                  sdk_name = "system-images;android-#{$1};#{$2};#{$3}"
                else
                  sdk_name = component
                end
                
                sh.cmd "yes | #{sdkmanager_bin} --sdk_root=#{android_home} \"#{sdk_name}\" --verbose", echo: true, timing: true
              end
            end
          else
            # Show available build-tools when none specified
            sh.echo "No build-tools version specified in android.components. Consider adding one of the following:", ansi: :yellow
            sh.cmd "#{sdkmanager_bin} --list | grep 'build-tools' | cut -d'|' -f1", echo: false, timing: false
            sh.echo "The following versions are preinstalled:", ansi: :yellow
            sh.cmd "for v in $(ls #{android_home}/build-tools | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false
          end
        end

        def script
          sh.if '-f gradlew' do
            sh.cmd './gradlew build connectedCheck', echo: true, timing: true
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle build connectedCheck', echo: true, timing: true
          end
          sh.elif '-f pom.xml' do
            sh.cmd 'mvn install -B', echo: true, timing: true
          end
          sh.else do
            sh.cmd 'ant debug install test', echo: true, timing: true
          end
        end

        def install
          sh.if "! -e #{gradle_path}" do
            sh.echo "Maven version is: $(mvn --version)", ansi: :yellow
            sh.echo "Gradle version is: $(gradle --version)", ansi: :yellow
          end
        end

        def cache_slug
          super << "--android-"
        end

        def use_jdk
          super
        end

        def announce_android
          super
        end

        private

        def gradle_path
          './gradlew'
        end

        def fold_options
          {
            animate: true,
            echo: true,
            timing: true
          }
        end
      end
    end
  end
end
