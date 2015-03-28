# Maintained by:
# Paul Cochrane    @paultcochrane   paul@liekut.de

module Travis
  module Build
    class Script
      class Perl6 < Script
        DEFAULTS = {
          perl6: 'latest'
        }

        def configure
          super

          sh.echo ''
          sh.echo 'Perl6 support for Travis-CI is community maintained.', ansi: :red
          sh.echo 'Please open any issues at https://github.com/travis-ci/travis-ci/issues/new', ansi: :red

          sh.echo 'Installing Rakudo (MoarVM)', ansi: :yellow
          sh.cmd 'git clone https://github.com/rakudo/rakudo.git'
          sh.cmd 'cd rakudo'
          sh.cmd 'sudo perl Configure.pl --backends=moar --gen-nqp --gen-moar --prefix=/usr'
          sh.cmd 'sudo make install'
        end

        def setup
          super
        end

        def announce
          super
          sh.cmd 'perl6 --version'
        end

        def install
        end

        def script
          sh.cmd 'make test'
        end

      end
    end
  end
end
