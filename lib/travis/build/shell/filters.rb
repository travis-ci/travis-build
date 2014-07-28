module Travis
  module Build
    module Shell
      module Filters
        module Assertion
          def code
            options[:assert] ? assert(super) : super
          end

          def assert(code)
            "#{code}\ntravis_assert"
          end
        end

        module Timing
          def code
            timing = options[:timing]
            echo = options[:echo]
            timing && echo ? measure(super) : super
          end

          def measure(code)
            "travis_time_start\n#{code}\ntravis_time_finish"
          end
        end

        module Echoize
          def code
            echo = options[:echo]
            echo ? echoize(super, echo.is_a?(String) ? echo : nil) : super
          end

          def echoize(code, echo = nil)
            if options[:store]
              "echo $TRAVIS_CMD\n#{code}"
            else
              "echo #{escape("$ #{echo || raw_code}")}\n#{code}"
            end
          end
        end

        module Retry
          def code
            code = options[:store] ? '$TRAVIS_CMD' : super
            options[:retry] ? retrying(code) : code
          end

          def retrying(code)
            "travis_retry #{code}"
          end
        end

        module Store
          def code
            options[:store] ? "TRAVIS_CMD=#{escape(raw_code)}\n#{super}" : super
          end
        end
      end
    end
  end
end
