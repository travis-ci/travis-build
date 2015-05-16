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
          sh.cmd 'git clone https://github.com/tadzik/rakudobrew.git $HOME/.rakudobrew'
          sh.export 'PATH', '$HOME/.rakudobrew/bin:$PATH', echo: false
        end

        def export
          super
          sh.export 'TRAVIS_PERL6_VERSION', version, echo: false
        end

        def setup
          super
          if version == "latest"
            sh.cmd 'rakudobrew build moar', assert: false
          else
            sh.cmd "rakudobrew triple #{version} #{version} #{version}", assert: false
          end
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

        def cache_slug
          super << '--perl6-' << version
        end

        def version
          config[:perl6].to_s
        end
      end
    end
  end
end
