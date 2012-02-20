require 'travis/build/job/test/jvm_language'

module Travis
  class Build
    module Job
      class Test
        # Using just "Java" clashes with JRuby's Java integration. MK.
        class PureJava < JvmLanguage
          class Config < Hashr
          end

          def install
            # prefer Gradle when both pom.xml and build.gradle exist in the repo. MK.
            if uses_gradle?
              install_dependencies_with_gradle
            elsif uses_maven?
              install_dependencies_with_maven
            end
          end

          def script
            if uses_gradle?
              run_tests_with_gradle
            elsif uses_maven?
              run_tests_with_maven
            else
              run_tests_with_ant
            end
          end
        end
      end
    end
  end
end
