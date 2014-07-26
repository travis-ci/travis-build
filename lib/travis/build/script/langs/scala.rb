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
          set 'TRAVIS_SCALA_VERSION', config[:scala]
        end

        def setup
          super
          sh.if '-d project || -f build.sbt' do
            sh.set 'JVM_OPTS', '@/etc/sbt/jvmopts'
            sh.set 'SBT_OPTS', '@/etc/sbt/sbtopts'
          end
        end

        def announce
          super
          echo "Using Scala #{config[:scala]}"
        end

        def install
          sh.if '! -d project && ! -f build.sbt' do
            super
          end
        end

        def script
          sh.if '-d project || -f build.sbt' do
            sh.cmd "sbt#{sbt_args} ++#{config[:scala]} test", echo: true
          end
          sh.else do
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
