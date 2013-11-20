module Travis
  module Build
    class Script
      class Android < Script
        include Jdk

        DEFAULTS = {
          sdk_components: %w[
            build-tools-19.0.0
            platform-tools
            android-19
            sysimg-19
            extra-android-support
            extra-android-m2repository
            extra-google-m2repository
            extra-google-google_play_services
          ]
        }

        def setup
          super
          install_components config[:sdk_components]
        end

        def install
          self.if   '-f gradlew',      './gradlew assemble', fold: 'install', retry: true
          self.elif '-f build.gradle', 'gradle assemble', fold: 'install', retry: true
          self.elif '-f pom.xml',      'mvn install -DskipTests=true -B', fold: 'install', retry: true # Otherwise mvn install will run tests which. Suggestion from Charles Nutter. MK.
        end

        def script
          self.if   '-f gradlew',      './gradlew check connectedCheck'
          self.if   '-f build.gradle', 'gradle check connectedCheck'
          self.elif '-f pom.xml',      'mvn test -B'
          self.else                    'ant debug installt test'
        end

        private

        def install_components(components)
          fold("android.install") do |script|
            echo "Installing Android dependencies"
            components.each do |component_name|
              install_sdk_component(script, component_name)
            end
          end
        end

        def install_sdk_component(script, component_name)
          script.cmd %{spawn android update sdk --filter #{component_name} --no-ui --force}
          script.cmd %{expect "Do you accept the license"}, echo: false
          script.cmd %{send "y\r"}, echo: false
          script.cmd %{interact},   echo: false
        end
      end
    end
  end
end
