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
              puts "result: #{result}"
              result
            end
          end
        end

        private

          def condition
            puts "TRAVIS_TEST_RESULT: #{TRAVIS_TEST_RESULT}"
            "$TRAVIS_TEST_RESULT #{operator} 0"
          end

          def operator
            puts "name: #{name}"
            name == :after_success ? '=' : '!='
          end
      end
    end
  end
end
