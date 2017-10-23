require 'forwardable'

module Travis
  module Build
    module Appliances
      class Base < Struct.new(:script)
        extend Forwardable

        def_delegators :script, :sh, :data, :config, :app_host

        def apply?
          true
        end
      end
    end
  end
end
