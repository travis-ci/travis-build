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
            shell.execute("phpenv global php-#{config.php}")
          end
          assert :setup

          def install
            "composer install #{config.composer_args}".strip if composer?
          end

          def script
            'phpunit'
          end

          protected

            def composer?
              shell.file_exists?('composer.json')
            end
            memoize :composer?
        end
      end
    end
  end
end
