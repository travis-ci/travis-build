module Travis
  module Build
    class Script
      module Jdk
        def export_jdk
          set 'TRAVIS_JDK_VERSION', config[:jdk] if config[:jdk]
        end

        def setup_jdk
          cmd "jdk_switcher use #{config[:jdk]}", assert: true if config[:jdk]
        end

        def announce
          super
          cmd "java -version"
          cmd "javac -version"
        end
      end
    end
  end
end
