module Travis
  class Build
    module Job
      class Test
        class Php < Test
          class Config < Hashr
            define :php => '5.3.8'
          end

          def setup
            super

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
            @uses_composer ||= shell.file_exists?('composer.json')

            # composer is not yet ready for prime time. MK.
            false
          end

          def announce_php
            shell.execute("php --version")
          end

          def export_environment_variables
            shell.export_line("TRAVIS_PHP_VERSION=#{config.php}")
          end
        end
      end
    end
  end
end
