require 'travis/build/script/shared/jvm'

module Travis
  module Build
    class Script
      # JRuby makes "Java" a reserved word so we cannot name our subclass like that
      class PureJava < Jvm
        DEFAULTS = {}
        # this builder completely inherits all the logic from the Jvm one. MK.
      end
    end
  end
end

