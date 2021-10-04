require 'shellwords'

module Travis
  module Vcs
    class Svn < Base
      class Submodules < Struct.new(:sh, :data)
        def apply
        end

        private

          def config
            data.config
          end
      end
    end
  end
end
