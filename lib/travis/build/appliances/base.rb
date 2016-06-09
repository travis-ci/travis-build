require 'forwardable'
require 'active_support/core_ext/string/inflections.rb'

module Travis
  module Build
    module Appliances
      class Base < Struct.new(:script)
        extend Forwardable

        def_delegators :script, :sh, :data, :config

        def apply?
          data.appliances_switches.fetch( to_key, true)
        end

        private

        def to_key
          self.class.name.split('::').last.underscore.to_sym
        end
      end
    end
  end
end
