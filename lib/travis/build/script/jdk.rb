module Travis
  module Build
    class Script
      module Jdk
        def export
          super
          set 'TRAVIS_JDK_VERSION', data[:jdk] if uses_jdk?
        end

        def setup
          super
          cmd "jdk_switcher use #{data[:jdk]}", assert: true if uses_jdk?
        end

        def announce
          super
          if uses_java?
            cmd "java -version"
            cmd "javac -version"
          end
        end

        private

          def uses_java?
            true
          end

          def uses_jdk?
            !!data[:jdk]
          end
      end
    end
  end
end
