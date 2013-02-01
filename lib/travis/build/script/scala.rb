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
          set 'TRAVIS_SCALA_VERSION', config[:scala], echo: false
        end

        def announce
          echo "Using Scala #{config[:scala]}"
        end

        def script
          sh_if   '-d project || -f build.sbt', "sbt ++#{config[:scala]} test"
          sh_elif   '-f build.gradle', 'gradle check'
          sh_else 'mvn test'
        end
      end
    end
  end
end

