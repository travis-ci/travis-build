module Travis
  module Build
    class Script
      class Android < Script
        include Jdk

        DEFAULTS = {
          android: {
            components: [],
            licenses: []
          }
        }

        def setup
          super
          if build_tools_desired.empty?
            echo <<-MSG, ansi: :yellow
No build-tools version is specified in android.components. Consider adding one of:
#{available_build_tools_versions.map {|v| "build-tools-#{v}"}.join("\n")}
The following versions are pre-installed: #{installed_build_tools_versions.join(" ")}
See http://docs.travis-ci.com/user/languages/android/#How-to-install-Android-SDK-components for more information.
            MSG
          end
          install_sdk_components(config[:android][:components]) unless config[:android][:components].empty?
        end

        def script
          self.if   '-f gradlew',      './gradlew build connectedCheck'
          self.elif '-f build.gradle', 'gradle build connectedCheck'
          self.elif '-f pom.xml',      'mvn install -B'
          self.else                    'ant debug installt test'
        end

        private

        def install_sdk_components(components)
          fold 'android.install' do |script|
            echo "Installing Android dependencies"
            components.each do |component_name|
              install_sdk_component(script, component_name)
            end
          end
        end

        def install_sdk_component(script, component_name)
          install_cmd = "android-update-sdk --components=#{component_name}"
          unless config[:android][:licenses].empty?
            install_cmd += " --accept-licenses='#{config[:android][:licenses].join('|')}'"
          end
          script.cmd install_cmd
        end

        def build_tools_desired
          config[:android][:components].map { |component|
            match = /build-tools-(?<version>[\d\.]+)/.match(component)
            match[:version] if match
          }
        end

        def available_build_tools_versions
          @available_build_tools_versions ||= `android list sdk --extended --no-ui --all | awk -F\\" '/^id.*build-tools/ {print $2}'`.split("\n").sort.reverse
        end

        def installed_build_tools_versions
          @installed_build_tools_versions ||= `ls /usr/local/android-sdk/build-tools/ 2>/dev/null`.split.sort.reverse
        end
      end
    end
  end
end
