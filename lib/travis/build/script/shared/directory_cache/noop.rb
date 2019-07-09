module Travis
  module Build
    class Script
      module DirectoryCache
        class Noop
          DATA_STORE = nil
          SIGNATURE_VERSION = nil

          EMPTY_BASH_METHODS = %i[
            fetch
            push
            add
          ]

          attr_reader :sh

          def initialize(sh, *args)
            @sh = sh
          end

          def method_missing(method, *args)
            if EMPTY_BASH_METHODS.include? method
              sh.raw ':'
            else
              self
            end
          end
        end
      end
    end
  end
end
