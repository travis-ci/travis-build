require 'travis/build/addons/base'
require 'travis/build/addons/sbom/script'

module Travis
  module Build
    class Addons
      class Sbom < Base
        SUPER_USER_SAFE = true

        def before_script?
          !config.empty? && config[:run_phase] == 'before_script'
        end

        def script?
          !config.empty? && config[:run_phase] == 'script'
        end

        def after_after_success?
          !config.empty? && config[:run_phase] == 'after_success'
        end

        def after_after_failure?
          !config.empty? && config[:run_phase] == 'after_failure'
        end

        def before_script
          Script.new(@script, sh, data, config).generate
        end

        def script
          Script.new(@script, sh, data, config).generate
        end

        def after_after_success
          sh.if('$TRAVIS_TEST_RESULT = 0') do
            Script.new(@script, sh, data, config).generate
          end
        end

        def after_after_failure
          sh.if('$TRAVIS_TEST_RESULT != 0') do
            Script.new(@script, sh, data, config).generate
          end
        end
      end
    end
  end
end
