require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Conditional < Base
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
