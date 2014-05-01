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
          install_sdk_components(config[:android][:components]) unless config[:android][:components].empty?
        end

        def install
          self.if   '-f gradlew',      './gradlew assemble', fold: 'install', retry: true
          self.elif '-f build.gradle', 'gradle assemble', fold: 'install', retry: true
          self.elif '-f pom.xml',      'mvn install -DskipTests=true -B', fold: 'install', retry: true # Otherwise mvn install will run tests which. Suggestion from Charles Nutter. MK.
        end

        def script
          self.if   '-f gradlew',      './gradlew check connectedCheck'
          self.elif '-f build.gradle', 'gradle check connectedCheck'
          self.elif '-f pom.xml',      'mvn test -B'
          self.else                    'ant debug installt test'
        end

        private

        def install_sdk_components(components)
          fold("android.install") do |script|
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
      end
    end
  end
end
