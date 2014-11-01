require 'travis/build/script/addons/base'
require 'travis/build/script/addons/deploy/script'

module Travis
  module Build
    class Script
      class Addons
        class Deploy < Base
          SUPER_USER_SAFE = true

          def initialize(sh, data, config)
            super(sh, data, config.is_a?(Array) ? config : [config])
          end

          def deploy
            providers.map(&:deploy)
          end

          private

            def providers
              config.map { |config| Script.new(sh, data, config) }
            end
        end
      end
    end
  end
end
