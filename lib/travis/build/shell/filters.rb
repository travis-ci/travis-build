require 'shellwords'

module Travis
  module Build
    module Shell
      module Filters
        module Logging
          def code
            options[:log] ? log(super) : super
          end

          def log(code)
            "(#{code}) >> #{options[:log_file]} 2>&1"
          end
        end

        module Timeout
          def code
            options[:timeout] ? timeout(super) : super
          end

          def timeout(code)
            "(#{code}) &\ntravis_timeout #{options[:timeout]}"
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
            options[:echo] ? echoize(super) : super
          end

          def echoize(code)
            # "echo #{Shellwords.escape("$ #{@code}")} >> #{options[:log_file]} 2>&1\n#{code}"
            "echo #{Shellwords.escape("$ #{@code}")}\n#{code}"
          end
        end
      end
    end
  end
end
