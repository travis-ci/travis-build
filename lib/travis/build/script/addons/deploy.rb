require 'travis/build/script/addons/deploy/script'

module Travis
  module Build
    class Script
      module Addons
        class Deploy
          SUPER_USER_SAFE = true

          attr_reader :providers

          def initialize(sh, data, config)
            config = config.is_a?(Array) ? config : [config]
            @providers = config.map { |config| Script.new(sh, data, config) }
          end

          def deploy
            providers.map(&:deploy)
          end
        end
      end
    end
  end
end
