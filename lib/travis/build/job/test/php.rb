require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Php < Test
          class Config < Hashr
            define :php => '5.3.8', :script => 'phpunit'
          end

          def setup
            shell.execute("phpenv global php-#{config.php}")
          end
          assert :setup
        end
      end
    end
  end
end
