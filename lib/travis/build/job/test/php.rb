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
            setup_php
            announce_php
          end

          def install
            "composer install #{config.composer_args}".strip if uses_composer?
          end

          def script
            'phpunit'
          end

          protected

            def setup_php
              shell.execute("phpenv global #{config.php}")
            end
            assert :setup_php

            def uses_composer?
              shell.file_exists?('composer.json')
              false
            end
            memoize :uses_composer?

            def announce_php
              shell.execute("php --version")
            end
        end
      end
    end
  end
end
