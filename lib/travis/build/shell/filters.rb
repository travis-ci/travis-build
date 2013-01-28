
module Travis
  module Build
    module Shell
      module Filters
        module Logging
          def code
            options[:log] && options[:log_file] ? log(super) : super
          end

          def log(code)
            "#{code} >> #{options[:log_file]} 2>&1"
          end
        end

        module Timeout
          def code
            options[:timeout] ? timeout(super) : super
          end

          def timeout(code)
            "tlimit -c #{options[:timeout]} #{code}"
          end
        end

        module Assertion
          def code
            options[:assert] ? assert(super) : super
          end

          def assert(code)
            "#{code}\ntravis_assert"
          end
        end

        module Echoize
          def code
            echo = options[:echo]
            echo ? echoize(super, echo.is_a?(String) ? echo : nil) : super
          end

          def echoize(code, echo = nil)
            "Write-Host \"#{escape("$ #{echo || @code}")}\"\n#{code}"
          end
        end
      end
    end
  end
end
