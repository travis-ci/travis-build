module Travis
  module Build
    class Script
      module Jdk
        def export_jdk
          set 'TRAVIS_JDK_VERSION', data[:jdk] if data[:jdk]
        end

        def setup_jdk
          cmd "jdk_switcher use #{data[:jdk]}", assert: true if data[:jdk]
        end

        # TODO should be announce_java so we don't announce in the ruby builder unless required
        # maybe have a use_jdk? which can be overwritten in ruby
        def announce
          super
          cmd "java -version"
          cmd "javac -version"
        end
      end
    end
  end
end
