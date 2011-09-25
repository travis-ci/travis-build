require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Php < Test
          class Config < Hashr
            define :php => '5.3.8'
          end

          extend ActiveSupport::Memoizable

          def setup
            setup_phpenv
          end

          protected

            def setup_phpenv
              shell.execute("phpenv global php-#{config.php}")
            end
            assert :setup_phpenv

            def script
              if config.script?
                config.script
              else
                'phpunit'
              end
            end
        end
      end
    end
  end
end

