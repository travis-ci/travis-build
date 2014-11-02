require 'travis/build/addons/base'
require 'travis/build/addons/deploy/script'

module Travis
  module Build
    class Addons
      class Deploy < Base
        SUPER_USER_SAFE = true

        def initialize(sh, data, config)
          super(sh, data, config.is_a?(Array) ? config : [config].compact)
        end

        def before_finish?
          !config.empty?
        end

        def before_finish
          sh.if('$TRAVIS_TEST_RESULT = 0') do
            providers.map(&:deploy)
          end
        end

        private

          def providers
            config.map { |config| Script.new(sh, data, config) }
          end
      end
    end
  end
end
