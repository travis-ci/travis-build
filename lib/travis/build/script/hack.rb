module Travis
  module Build
    class Script
      class Hack < Php
        DEFAULTS = {
          php: '7.3',
          composer: '--no-interaction --prefer-source',
          hhvm: 'hhvm-4.25'
        }

        def configure
          unless hhvm?
            sh.terminate 2, "Hack requires HHVM, but HHVM is not configured with \`hhvm:\`. Terminating.", ansi: :red
          end
        end

        def announce
          super
          sh.cmd 'hhvm --version'
        end

        def install
          sh.cmd 'composer install', echo: true, timing: true
        end

        def script
          sh.cmd 'hh_client', echo: true, timing: true
          sh.if "test -x vendor/bin/hacktest" do
            sh.cmd 'vendor/bin/hacktest tests/', echo: true, timing: true
          end
          sh.if '!(hhvm --version | grep -q -- -dev) && test -x vendor/bin/hhast-lint' do
            sh.cmd 'vendor/bin/hhast-lint'
          end
        end

        def cache_slug
          super << '--hhvm-' << hhvm_version
        end
      end
    end
  end
end
