require 'travis/build/script/addons/deploy/provider'

module Travis
  module Build
    class Script
      module Addons
        class Deploy
          SUPER_USER_SAFE = true

          attr_reader :script, :config

          def initialize(script, config)
            @script = script
            @config = config.is_a?(Array) ? config : [config]
          end

          def deploy
            config.each do |config|
              Provider.new(script, config).deploy
            end
          end
        end
      end
    end
  end
end
