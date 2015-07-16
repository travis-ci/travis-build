require 'travis/build/script/shared/jvm'

module Travis
  module Build
    class Script
      class Groovy < Jvm
        DEFAULTS = {}
        # this builder completely inherits all the logic from the Jvm one. MK.
      end
    end
  end
end

