module Travis
  module Build
    class Script
      class Scala < Script
        include Jdk

        DEFAULTS = {
          scala: '2.10.0',
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
          self.if   '-d project || -f build.sbt', "sbt ++#{config[:scala]} test"
          self.elif '-f build.gradle', 'gradle check'
          self.else 'mvn test'
        end
      end
    end
  end
end

