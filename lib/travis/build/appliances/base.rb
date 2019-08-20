require 'forwardable'

module Travis
  module Build
    module Appliances
      class Base < Struct.new(:script)
        extend Forwardable

        def_delegators :script, :sh, :data, :config, :app_host, :bash

        def apply?
          not windows?
        end

        def windows?
          config[:os] == 'windows'
        end

        def linux?
          config[:os] == 'linux'
        end

        def time?
          true
        end
      end
    end
  end
end
