require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Skip < Base
        def run
          sh.raw 'travis_result 0' if script?
        end
      end
    end
  end
end
