require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Conditional < Base
        def run
          return unless config[name] || deployment? || sbom?

          result = Custom.new(script, name).run
          unless result.empty?
            sh.if(condition) do
              result
            end
          end
        end

        private

          def condition
            "$TRAVIS_TEST_RESULT #{operator} 0"
          end

          def operator
            name == :after_success ? '-eq' : '-ne'
          end
      end
    end
  end
end
