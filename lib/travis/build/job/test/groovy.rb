require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        # Using just "Java" clashes with JRuby's Java integration. MK.
        class Groovy < Test
          class Config < Hashr
          end

          extend ActiveSupport::Memoizable

          def setup
          end

          def install
            if uses_gradle?
              "gradle assemble"
            elsif uses_maven?
              # otherwise mvn install will run tests
              # and we do not want it. Per suggestion from Charles Nutter. MK.
              "mvn install -DskipTests=true"
            end
          end

          def script
            if uses_gradle?
              "gradle check"
            elsif uses_maven?
              "mvn test"
            else
              "ant test"
            end
          end

          protected

          def uses_maven?
            shell.file_exists?('pom.xml')
          end
          memoize :uses_maven?

          def uses_gradle?
            shell.file_exists?('build.gradle')
          end
          memoize :uses_gradle?
        end
      end
    end
  end
end
