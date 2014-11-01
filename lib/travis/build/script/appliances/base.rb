require 'forwardable'

module Travis
  module Build
    class Script
      module Appliances
        class Base < Struct.new(:script)
          extend Forwardable

          def_delegators :script, :sh, :data, :config

          def apply?
            true
          end
        end
      end
    end
  end
end
