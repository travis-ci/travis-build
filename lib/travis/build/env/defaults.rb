require 'travis/build/env/base'

module Travis
  module Build
    class Env
      class Defaults < Base
        DEFAULTS = {
          CFLAGS:  '-w',
          CCFLAGS: '-w',
        }

        def announce?
          false
        end

        def vars
          DEFAULTS.map do |var, val|
            Var.new(var, val, type: :defaults)
          end
        end
      end
    end
  end
end
