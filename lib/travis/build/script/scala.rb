require 'travis/build/script/shared/jvm'

module Travis
  module Build
    class Script
      class Scala < Jvm

        DEFAULTS = {
          scala: '2.10.4',
          jdk:   'default'
        }

        def export
          super
          sh.export 'TRAVIS_SCALA_VERSION', version, echo: false
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
          sh.echo "Using Scala #{version}"
        end

        def install
          sh.if '! -d project && ! -f build.sbt' do
            super
          end
        end

        def script
          sh.if '-d project || -f build.sbt' do
            sh.cmd "sbt#{sbt_args} ++#{version} test"
          end
          sh.else do
            super
          end
        end

        def cache_slug
          super << "--scala-" << version
        end

        private

          def version
            config[:scala].to_s
          end

          def sbt_args
            config[:sbt_args] && " #{config[:sbt_args]}"
          end
      end
    end
  end
end
