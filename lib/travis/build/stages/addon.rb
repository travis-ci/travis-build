require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Addon < Base
        def run
          with_stage(name) { script.addons.run_stage(name) } if run?
        end

        def run?
          script.respond_to?(:addons)
        end
      end
    end
  end
end
