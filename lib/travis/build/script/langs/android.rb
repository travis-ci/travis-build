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
          install_sdk_components(components) unless components.empty?
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
            # TODO is that really `installt` (ending with a t?)
            sh.cmd 'ant debug installt test'
          end
        end

        private

          def install_sdk_components(components)
            sh.fold 'android.install' do
              sh.echo "Installing Android dependencies"
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
        end

        def components
          config[:android][:components]
        end

        def licenses
          config[:android][:licenses]
        end
    end
  end
end
