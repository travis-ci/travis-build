require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Android < Script
        DEFAULTS = {}

        include Jdk

        def setup
          super
          
          if ubuntu_trusty?
            setup_trusty
          else
            setup_newer
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

        def ubuntu_trusty?
          result = `lsb_release -cs`.strip
          result == "trusty"
        rescue
          false
        end

        def setup_trusty
          if build_tools_desired.empty?
            sh.echo "No build-tools version is specified in android.components. Consider adding one of:", ansi: :yellow
            sh.cmd "android list sdk --extended --no-ui --all | awk -F\" '/^id.*build-tools/ {print $2}'", echo: false, timing: false
            sh.echo "The following versions are pre-installed:", ansi: :yellow
            sh.cmd "for v in $(ls /usr/local/android-sdk/build-tools/ | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false
          end
          install_sdk_components unless components.empty?
          ensure_tools_bin_path
        end

        def setup_newer
          set_android_environment_variables
          if build_tools_desired.empty?
            sh.echo "No build-tools version specified in android.components. Consider adding one of the following:", ansi: :yellow
            sh.cmd "sdkmanager --list | grep 'build-tools' | cut -d'|' -f1", echo: false, timing: false
            sh.echo "The following versions are preinstalled:", ansi: :yellow
            sh.cmd "for v in $(ls #{android_sdk_build_tools_dir} | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false
          end
          install_sdk_components unless components.empty?
        end

        def set_android_environment_variables
          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          sh.export 'ANDROID_HOME', android_home
          
          # Używamy ścieżki /usr/local/android-sdk/cmdline-tools/bin, gdzie znajduje się sdkmanager
          sdkmanager_path = if File.directory?("#{android_home}/cmdline-tools/bin")
                              "#{android_home}/cmdline-tools/bin"
                            else
                              "#{android_home}/cmdline-tools/latest/cmdline-tools/bin"
                            end

          sh.export 'PATH', "#{sdkmanager_path}:#{android_home}/tools:#{android_home}/tools/bin:#{android_home}/platform-tools:$PATH"
        end

        def install_sdk_components
          sh.fold 'android.install' do
            sh.echo 'Installing Android dependencies'
            components.each do |name|
              sh.cmd install_sdk_component(name)
            end
          end
        end

        def install_sdk_component(name)
          if ubuntu_trusty?
            accept = licenses.any? ? " --accept-licenses='#{licenses.join('|')}'" : ""
            "android-update-sdk --components=#{name}#{accept}"
          else
            android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
            sdk_name = case name
                       when /^build-tools-(.+)$/
                         "build-tools;#{$1}"
                       when /^platforms-android-(.+)$/
                         "platforms;android-#{$1}"
                       when /^android-(.+)$/
                         "platforms;android-#{$1}"
                       when /^system-images-android-(.+)-(.+)-(.+)$/
                         "system-images;android-#{$1};#{$2};#{$3}"
                       when /^extra-google-google_play_services$/
                         "extras;google;google_play_services"
                       when /^extra-google-m2repository$/
                         "extras;google;m2repository"
                       when /^extra-android-m2repository$/
                         "extras;android;m2repository"
                       else
                         name
                       end
            "yes | sdkmanager --sdk_root=#{android_home} \"#{sdk_name}\" --verbose"
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
          android_home = ENV['ANDROID_HOME'] || '/usr/local/android-sdk'
          File.join(android_home, 'build-tools')
        end

        def ensure_tools_bin_path
          tools_bin_path = '/usr/local/android-sdk/tools/bin'
          sh.if "$(echo :$PATH: | grep -v :#{tools_bin_path}:)" do
            sh.export "PATH", "#{tools_bin_path}:$PATH"
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
