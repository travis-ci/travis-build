# Maintained by:
# Paul Cochrane    @paultcochrane   paul@liekut.de
# Rob Hoelz        @hoelzro         rob@hoelz.ro
# Nick Logan       @ugexe           nlogan@gmail.com
# Tony O'Dell      @tony-o          tony.odell@live.com

module Travis
  module Build
    class Script
      class Raku < Script
        DEFAULTS = {
          raku: 'latest'
        }

        def export
          super
          sh.export 'TRAVIS_RAKU_VERSION', version, echo: false
        end

        def configure
          super

          sh.newline
          sh.echo 'Raku support for Travis-CI is community maintained.', ansi: :red
          sh.echo 'Please open any issues at https://travis-ci.community/c/languages/raku', ansi: :red
          sh.echo 'and cc @paultcochrane, @hoelzro, @ugexe, and @tony-o', ansi: :red

          sh.echo 'Installing Rakudo (MoarVM)', ansi: :yellow
          sh.cmd 'git clone -b v1 https://github.com/Raku/App-Rakubrew.git ${TRAVIS_HOME}/.rakubrew'
          sh.export 'PATH', '${TRAVIS_HOME}/.rakubrew/bin:$PATH', echo: false
        end

        def setup
          super
          if version == "latest"
            sh.cmd 'rakubrew build master',
              assert: false, fold: 'setup', timing: true
          else
            sh.cmd "if [ \"$(rakubrew available | grep 'D' | grep '#{version}')\" == '' ]; then rakubrew build moar '#{version}'; else rakubrew download moar '#{version}'; fi",
              assert: false, fold: 'setup', timing: true
          end
        end

        def announce
          super
          sh.cmd 'raku --version'
        end

        def install
        end

        def script
          sh.cmd "RAKULIB=lib prove --ext .t --ext .t6 -v -r --exec=raku t/"
        end

        def cache_slug
          super << '--raku-' << version
        end

        def version
          Array(config[:raku]).first.to_s
        end
      end
    end
  end
end
