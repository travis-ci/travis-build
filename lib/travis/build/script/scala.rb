module Travis
  module Build
    class Script
      class Scala < Script
        include Jdk

        DEFAULTS = {
          scala: '2.9.2',
          jdk:   'default'
        }

        def export
          super
          set 'TRAVIS_SCALA_VERSION', data[:scala]
        end

        def setup
          super
          setup_jdk
        end

        def announce
          echo "Using Scala #{data[:scala]}"
        end

        def script
          sh_if   '-f project || -f build.sbt', "sbt ++#{data[:scala]} test"
          sh_else 'mvn test'
        end
      end
    end
  end
end

