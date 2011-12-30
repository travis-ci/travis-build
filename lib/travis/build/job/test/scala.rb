require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Scala < Test
          class Config < Hashr
            define :scala => '2.9.1'
          end

          extend ActiveSupport::Memoizable

          def setup
            define_scala
            # version is switched by sbt "++<scala-version>" parameter in 'script' step 
          end

          def install
            # return nil by default, because sbt (with the help of Apache Ivy)
            # automagically handle unmanaged and managed dependencies
          end

          def script
            "sbt ++#{config.scala} test" if configured_for_sbt?
          end

          protected

          def configured_for_sbt?
            shell.file_exists?('project') || shell.file_exists?('build.sbt')
          end
          memoize :configured_for_sbt?

          def define_scala
            # export expected Scala version in an environment variable as helper
            # for cross-version build in custom scripts (ant, maven, local sbt,...)
            shell.export_line("SCALA_VERSION=#{config.scala}") 
            shell.echo("Expect to build with Scala #{config.scala}")
          end

        end
      end
    end
  end
end
