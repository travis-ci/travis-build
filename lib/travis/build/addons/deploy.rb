require 'travis/build/addons/base'
require 'travis/build/addons/deploy/script'

module Travis
  module Build
    class Addons
      class Deploy < Base
        SUPER_USER_SAFE = true

        def initialize(script, sh, data, config)
          super(script, sh, data, config.is_a?(Array) ? config : [config].compact)
        end

        def after_after_success?
          !config.empty?
        end

        def after_after_success
          # sh.if('$TRAVIS_TEST_RESULT = 0') do
          #   providers.map(&:deploy)
          # end
          providers.map(&:deploy)
        end

        private

          def providers
            config.map { |config| Script.new(script, sh, data, config) }
          end
      end
    end
  end
end
