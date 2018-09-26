require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Skip < Base
        def run
          sh.echo "Skipping the #{name} step, as specified in the configuration."
          sh.raw 'travis_result 0' if script?
        end
      end
    end
  end
end
