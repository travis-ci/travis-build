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
          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          
          sdkmanager_path = if File.exist?(File.join(android_home, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'))
                              File.join(android_home, 'cmdline-tools', 'latest', 'bin')
                            else
                              File.join(android_home, 'cmdline-tools', 'bin')
                            end

          sh.export 'ANDROID_HOME', android_home
          sh.export 'PATH', "#{sdkmanager_path}:#{android_home}/tools:#{android_home}/tools/bin:#{android_home}/platform-tools:$PATH"
        end

        def install_sdk_components
          sh.fold 'android.install' do
            sh.echo 'Installing Android dependencies'

            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            sdkmanager_path = if File.exist?(File.join(android_home, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'))
                                File.join(android_home, 'cmdline-tools', 'latest', 'bin', 'sdkmanager')
                              else
                                File.join(android_home, 'cmdline-tools', 'bin', 'sdkmanager')
                              end

            sh.cmd "yes | #{sdkmanager_path} --licenses >/dev/null || true", echo: true

            components.each do |name|
              sh.cmd install_sdk_component(name)
            end
          end
        end

        def install_sdk_component(name)
          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          sdkmanager_path = if File.exist?(File.join(android_home, 'cmdline-tools', 'latest', 'bin', 'sdkmanager'))
                              File.join(android_home, 'cmdline-tools', 'latest', 'bin', 'sdkmanager')
                            else
                              File.join(android_home, 'cmdline-tools', 'bin', 'sdkmanager')
                            end

          sdk_name = case name
                     when /^build-tools-(.+)$/ then "build-tools;#{$1}"
                     when /^platform-tools$/ then "platform-tools"
                     when /^tools$/ then "tools"
                     when /^platforms-android-(.+)$/ then "platforms;android-#{$1}"
                     when /^system-images-android-(.+)-(.+)-(.+)$/ then "system-images;android-#{$1};#{$2};#{$3}"
                     else name
                   end

          "yes | #{sdkmanager_path} \"#{sdk_name}\" --verbose"
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
