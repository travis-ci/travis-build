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
      end
    end
  end
end
