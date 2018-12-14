require 'travis/build/script/shared/jvm'

module Travis
  module Build
    class Script
      class Scala < Jvm

        DEFAULTS = {
          scala: '2.12.8',
          jdk:   'default'
        }

        SBT_PATH = '/usr/local/bin/sbt'
        SBT_SHA  = '4ad1b8a325f75c1a66f3fd100635da5eb28d9c91'
        SBT_URL  = "https://raw.githubusercontent.com/paulp/sbt-extras/#{SBT_SHA}/sbt"

        def configure
          super
          if use_sbt?
            sh.echo "Updating sbt", ansi: :green

            update_sbt
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
            Array(config[:scala]).first.to_s
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

          def update_sbt
            return if app_host.empty?

            sh.cmd "curl -sf -o sbt.tmp https://#{app_host}/files/sbt", echo: false
            sh.if "$? -ne 0" do
              sh.cmd "curl -sf -o sbt.tmp #{SBT_URL}", assert: true
            end
            sh.raw "sed -e '/addSbt \\(warn\\|info\\)/d' sbt.tmp | sudo tee #{SBT_PATH} > /dev/null && rm -f sbt.tmp"
            sh.chmod "+x", SBT_PATH, sudo: true
          end
      end
    end
  end
end
