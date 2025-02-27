require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {}

        include Jdk

        def setup
          super

          if build_tools_desired.empty?
            sh.echo "No build-tools version specified in android.components. Consider adding one of the following:", ansi: :yellow
            sh.cmd "sdkmanager --list | awk '/build-tools/ {print $1}'", echo: false, timing: false
            sh.echo "The following versions are preinstalled:", ansi: :yellow
            sh.cmd "for v in $(ls #{android_sdk_build_tools_dir} | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false
          end

          install_sdk_components unless components.empty?

          ensure_tools_bin_path
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

          def install_sdk_components
            sh.fold 'android.install' do
              sh.echo 'Installing Android dependencies'
              components.each do |name|
                sh.cmd install_sdk_component(name)
              end
              # Accepting licenses - required for some installations
              sh.cmd 'yes | sdkmanager --licenses', echo: true
            end
          end

          def install_sdk_component(name)
            # Convert name from format "build-tools-31.0.0" to "build-tools;31.0.0" for sdkmanager
            sdk_name = if name =~ /^build-tools-(.+)$/
                         "build-tools;#{$1}"
                       else
                         name
                       end
            "sdkmanager \"#{sdk_name}\""
          end

          def build_tools_desired
            components.map do |component|
              if component =~ /^build-tools-(?<version>[\d\.]+)$/
                Regexp.last_match[:version]
              end
            end.compact
          end

          def ensure_tools_bin_path
            # Determine the path to cmdline-tools using ANDROID_HOME if available
            tools_bin_path = if ENV['ANDROID_HOME']
                               File.join(ENV['ANDROID_HOME'], 'cmdline-tools', 'latest', 'bin')
                             else
                               '/usr/local/android-sdk/android-sdk/cmdline-tools/latest/cmdline-tools/bin/sdkmanager'
                             end
            sh.if "$(echo :$PATH: | grep -v :#{tools_bin_path}:)" do
              sh.export "PATH", "#{tools_bin_path}:$PATH"
            end
          end

          def android_sdk_build_tools_dir
            # Determine build-tools directory based on ANDROID_HOME
            if ENV['ANDROID_HOME']
              File.join(ENV['ANDROID_HOME'], 'build-tools')
            else
              '/usr/local/android-sdk/build-tools'
            end
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
