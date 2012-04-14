module Travis
  class Build
    module Job
      class Test
        class Scala < Test
          class Config < Hashr
            define :scala => 'undefined'
          end

          def setup
            super
            # Tell what version of Scala is expected (or display 'undefined' if managed by build tool)
            shell.echo("Expect to run tests with Scala version '#{config.scala}'")
          end

          def install
            # return nil by default, because sbt (with the help of Apache Ivy)
            # automagically handle unmanaged and managed dependencies
          end

          def script
            if uses_sbt?
              if uses_travis_matrix?
                "sbt ++#{config.scala} test"
              else
                "sbt test"
              end
            else
              "mvn test"
            end
          end

          protected

            def uses_sbt?
              @uses_sbt ||= (shell.directory_exists?('project') || shell.file_exists?('build.sbt'))
            end

            def uses_travis_matrix?
              @uses_travis_matrix ||= (config.scala != 'undefined')
            end

            def export_environment_variables
              # export expected Scala version in an environment variable as helper
              # for cross-version build in custom scripts (ant, maven, local sbt,...)
              shell.export_line("TRAVIS_SCALA_VERSION=#{config.scala}")
            end
        end
      end
    end
  end
end
