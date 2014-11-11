module Travis
  module Build
    class Script
      module Jdk
        def export
          super
          sh.export 'TRAVIS_JDK_VERSION', config[:jdk], echo: false if uses_jdk?
        end

        def setup
          super
          sh.cmd "jdk_switcher use #{config[:jdk]}", assert: true, timing: false if uses_jdk?
          sh.if '-f build.gradle' do
            sh.export 'TERM', 'dumb', echo: false
          end
        end

        def announce
          super
          if uses_java?
            sh.cmd 'java -version'
            sh.cmd 'javac -version'
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
