module Travis
  module Build
    class Script
      module Jdk
        def export
          super
          set 'TRAVIS_JDK_VERSION', config[:jdk], echo: false if uses_jdk?
        end

        def setup
          super
          cmd "jdk_switcher use #{config[:jdk]}", assert: true, timing: false if uses_jdk?
          self.if '-f build.gradle' do
            set 'TERM', 'dumb', echo: false
          end
        end

        def announce
          super
          if uses_java?
            cmd "java -version", timing: false
            cmd "javac -version", timing: false
          end
        end

        def cache_slug
          return super unless uses_jdk?
          super << "--jdk-" << config[:jdk].to_s
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
