module Travis
  module Build
    class Script
      class Scala < Jvm

        DEFAULTS = {
          scala: '2.10.3',
          jdk:   'default'
        }

        def cache_slug
          super << "--scala-" << config[:scala].to_s
        end

        def export
          super
          set 'TRAVIS_SCALA_VERSION', config[:scala], echo: false
        end

        def announce
          super
          echo "Using Scala #{config[:scala]}"
        end

        def install
          self.if  ('! -d project && ! -f build.sbt') { super }
        end

        def script
          self.if   '-d project || -f build.sbt', "sbt#{sbt_args} ++#{config[:scala]} test"
          self.else { super }
        end

        private

        def sbt_args
          config[:sbt_args] && " #{config[:sbt_args]}"
        end
      end
    end
  end
end
