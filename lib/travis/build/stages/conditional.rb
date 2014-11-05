require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Conditional < Base
        def run
          return unless config[name] || deployment?
          sh.if(condition) do
            Custom.new(script, name).run
          end
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
