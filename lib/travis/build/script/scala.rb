require 'travis/build/script/shared/jvm'

module Travis
  module Build
    class Script
      class Scala < Jvm

        DEFAULTS = {
          scala: '2.10.4',
          jdk:   'default'
        }

        SBT_PATH = '/usr/local/bin/sbt'
        SBT_SHA  = 'b9c8cb273d38e0d8da9211902a18018fe82aa14e'
        SBT_URL  = "https://raw.githubusercontent.com/paulp/sbt-extras/#{SBT_SHA}/sbt"

        def configure
          super
          if use_sbt?
            sh.echo "Updating sbt", ansi: :green
            sh.cmd "sudo curl -sS -o #{SBT_PATH} #{SBT_URL}"
          end
        end

        def export
          super
          sh.export 'TRAVIS_SCALA_VERSION', version, echo: false
        end

        def setup
          super
          sh.if use_sbt? do
            sh.export 'JVM_OPTS', '@/etc/sbt/jvmopts', echo: true
            sh.export 'SBT_OPTS', '@/etc/sbt/sbtopts', echo: true
          end
        end

        def announce
          super
          sh.echo "Using Scala #{version}"
        end

        def install
          sh.if not_use_sbt? do
            super
          end
        end

        def script
          sh.if use_sbt? do
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

          def use_sbt?
            '-d project || -f build.sbt'
          end

          def not_use_sbt?
            '! -d project && ! -f build.sbt'
          end
      end
    end
  end
end
