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
          sh.export 'TRAVIS_SCALA_VERSION', config[:scala], echo: false
        end

        def setup
          super
          sh.if '-d project || -f build.sbt' do
            sh.export 'JVM_OPTS', '@/etc/sbt/jvmopts', echo: true
            sh.export 'SBT_OPTS', '@/etc/sbt/sbtopts', echo: true
          end
        end

        def announce
          super
          sh.echo "Using Scala #{config[:scala]}"
        end

        def install
          sh.if '! -d project && ! -f build.sbt' do
            super
          end
        end

        def script
          sh.if '-d project || -f build.sbt', "sbt#{sbt_args} ++#{config[:scala]} test"
          sh.else { super }
        end

        private

        def sbt_args
          config[:sbt_args] && " #{config[:sbt_args]}"
        end
      end
    end
  end
end
