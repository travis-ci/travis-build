module Travis
  module Build
    class Script
      class Scala < Jvm

        DEFAULTS = {
          scala: '2.10.4',
          jdk:   'default'
        }

        def cache_slug
          super << "--scala-" << config[:scala].to_s
        end

        def export
          super
          set 'TRAVIS_SCALA_VERSION', config[:scala], echo: false
        end

        def setup
          super
          self.if '-d project || -f build.sbt' do
            set 'JVM_OPTS', '@/etc/sbt/jvmopts', echo: true
            set 'SBT_OPTS', '@/etc/sbt/sbtopts', echo: true
          end
        end

        def announce
          super
          echo "Using Scala #{config[:scala]}"
        end

        def install
          self.if '! -d project && ! -f build.sbt' do
            super
          end
        end

        def script
          self.if '-d project || -f build.sbt', "sbt#{sbt_args} ++#{config[:scala]} test"
          self.else do
            super
          end
        end

        private

        def sbt_args
          config[:sbt_args] && " #{config[:sbt_args]}"
        end
      end
    end
  end
end
