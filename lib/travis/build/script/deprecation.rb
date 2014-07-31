module Travis
  module Build
    class Script
      module Deprecation
        class << self
          def deprecations
            @deprecations ||= []
          end
        end

        def deprecations
          Deprecation.deprecations
        end

        def deprecate(msg)
          deprecations << msg unless deprecations.include?(msg)
        end
      end
    end
  end
end
