require 'hashr'

module Travis
  class Build
    module Job
      class Test
        class Perl < Test
          class Config < Hashr
            define :perlbrew => '5.14'
          end

          def setup
            super

            setup_perl
            announce_perl
          end

          def script
            "cpanm . -v --no-interactive"
          end

          protected

          def setup_perl
            shell.execute("perlbrew use #{config.perlbrew}")
          end
          assert :setup_perl

          def announce_perl
            shell.execute("perl --version")
          end

          def export_environment_variables
            shell.export_line("TRAVIS_PERL_VERSION=#{config.perlbrew}")
          end
        end
      end
    end
  end
end
