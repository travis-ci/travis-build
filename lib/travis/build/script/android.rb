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
          sh.if   '-f gradlew',      './gradlew build connectedCheck'
          sh.elif '-f build.gradle', 'gradle build connectedCheck'
          sh.elif '-f pom.xml',      'mvn install -B'
          sh.else                    'ant debug installt test'
        end

        private

        def install_sdk_components(components)
          sh.fold 'android.install' do
            sh.echo 'Installing Android dependencies'
            components.each do |component_name|
              install_sdk_component(sh, component_name)
            end
          end
        end

        def install_sdk_component(sh, component)
          cmd = "android-update-sdk --components=#{component}"
          cmd += " --accept-licenses='#{licenses}'" unless licenses.empty?
          sh.cmd cmd
        end

        def licenses
          Array(config[:android][:licenses]).join('|')
        end
      end
    end
  end
end
