module Travis
  module Build
    class Script
      module DirectoryCache
        class Noop
          DATA_STORE = nil
          SIGNATURE_VERSION = nil

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
