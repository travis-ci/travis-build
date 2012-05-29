module Travis
  class Build
    module Job
      class Test
        class Scala < Test
          include JdkSwitcher

          class Config < Hashr
            define :scala => '2.9.2', :jdk => 'default'
          end

          def setup
            super
            setup_jdk
            shell.echo("Using Scala #{config.scala}")
          end

          def install
            # return nil by default, because sbt (with the help of Apache Ivy)
            # automagically handle unmanaged and managed dependencies
          end

          def script
            if uses_sbt?
              "sbt ++#{config.scala} test"
            else
              "mvn test"
            end
          end

          protected

            def uses_sbt?
              @uses_sbt ||= (shell.directory_exists?('project') || shell.file_exists?('build.sbt'))
            end

            def export_environment_variables
              export_jdk_environment_variables
              # export expected Scala version in an environment variable as helper
              # for cross-version build in custom scripts (ant, maven, local sbt,...)
              shell.export_line("TRAVIS_SCALA_VERSION=#{config.scala}")
            end
        end
      end
    end
  end
end
