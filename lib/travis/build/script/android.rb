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
            sh.echo "No build-tools version is specified in android.components. Consider adding one of:", ansi: :yellow
            sh.cmd  "android list sdk --extended --no-ui --all | awk -F\\\" '/^id.*build-tools/ {print $2}'", echo: false, timing: false
            sh.echo "The following versions are pre-installed:", ansi: :yellow
            sh.cmd  "for v in $(ls /usr/local/android-sdk/build-tools/ | sort -r 2>/dev/null); do echo build-tools-$v; done; echo", echo: false, timing: false
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
            end
          end

          def install_sdk_component(name)
            code = "android-update-sdk --components=#{name}"
            code << " --accept-licenses='#{licenses.join('|')}'" unless licenses.empty?
            code
          end

          def build_tools_desired
            components.map { |component|
              match = /build-tools-(?<version>[\d\.]+)/.match(component)
              match[:version] if match
            }
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
