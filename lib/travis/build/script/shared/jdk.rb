module Travis
  module Build
    class Script
      module Jdk
        def configure
          super
          sh.cmd "jdk_switcher use #{config[:jdk]}", assert: true, echo: true, timing: false if uses_jdk?
        end

        def export
          super
          sh.export 'TRAVIS_JDK_VERSION', config[:jdk], echo: false if uses_jdk?
        end

        def setup
          super
          sh.if '-f build.gradle || -f build.gradle.kts' do
            sh.export 'TERM', 'dumb'
          end

          sh.echo "Disabling Gradle daemon", ansi: :yellow
          sh.cmd 'mkdir -p ~/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties', echo: true
        end

        def announce
          super
          if uses_java?
            sh.cmd 'java -Xmx32m -version'
            sh.cmd 'javac -J-Xmx32m -version'
          end
        end

        def cache_slug
          return super unless uses_jdk?
          super << '--jdk-' << config[:jdk].to_s
        end

        private

          def uses_java?
            true
          end

          def uses_jdk?
            !!config[:jdk]
          end
      end
    end
  end
end
