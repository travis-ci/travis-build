module Travis
  module Build
    class Script
      module DirectoryCache
        class Noop
          def initialize(*)
          end

          def method_missing(*)
            self
          end
        end
      end
    end
  end
end
