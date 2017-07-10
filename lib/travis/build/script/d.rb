# Community maintainers:
#
#   Martin Nowak <code dawg eu, @MartinNowak>
#
module Travis
  module Build
    class Script
      class D < Script
        DEFAULTS = {
          d: 'dmd'
        }.freeze

        def cache_slug
          super << '--d-' << config[:d]
        end

        def setup
          super

          sh.echo 'D support for Travis-CI is community maintained.', ansi: :green
          sh.echo 'Please make sure to ping @MartinNowak, @klickverbot and @ibuclaw '\
            'when filing issues under https://github.com/travis-ci/travis-ci/issues.', ansi: :green

          sh.fold 'compiler-download' do
            sh.echo 'Installing compiler and dub', ansi: :yellow

            sh.cmd 'CURL_USER_AGENT="Travis-CI $(curl --version | head -n 1)"'
            sh.cmd <<-'EOT'.gsub(/^              /, '')
              for i in {0..4}; do
                  if curl -fsS -A "$CURL_USER_AGENT" --max-time 5 https://dlang.org/install.sh -O ||
                          curl -fsS -A "$CURL_USER_AGENT" --max-time 5 https://nightlies.dlang.org/install.sh -O; then
                      break
                  elif [ $i -lt 4 ]; then
                      sleep $((1 << $i))
                  fi
              done
            EOT
            sh.cmd "source \"$(CURL_USER_AGENT=\"$CURL_USER_AGENT\" bash install.sh #{config[:d]} --activate)\""
          end
        end

        def announce
          super
          if config[:d].start_with?('dmd-') && config[:d] <= 'dmd-2.066.1'
            sh.cmd 'dmd --help | head -n 2'
          else
            sh.cmd '$DC --version'
          end
          sh.cmd 'dub --help | tail -n 1'
        end

        def script
          sh.cmd 'dub test --compiler=$DC'
        end
      end
    end
  end
end
