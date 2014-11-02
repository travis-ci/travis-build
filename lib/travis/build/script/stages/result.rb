module Travis
  module Build
    class Script
      class Stages
        class Result < Base
          def run
            sh.if(condition) { Custom.new(script, name).run } if config[name]
          end

          private

            def condition
              "$TRAVIS_TEST_RESULT #{operator} 0"
            end

            def operator
              name == :after_success ? '=' : '!='
            end
        end
      end
    end
  end
end
