# Community maintainers:
#
#   Martin Nowak <code dawg eu, @MartinNowak>
#   Sebastian Wilzbach <seb wilzba ch, @wilzbach>
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
          sh.echo 'Please make sure to ping @MartinNowak and @wilzbach '\
            'when filing issues under https://travis-ci.community/c/languages/d.', ansi: :green

          sh.echo 'DMD-related issues: https://issues.dlang.org', ansi: :green
          sh.echo 'LDC-related issues: https://github.com/ldc-developers/ldc/issues', ansi: :green
          sh.echo 'GDC-related issues: https://bugzilla.gdcproject.org', ansi: :green
          sh.echo 'DUB-related issues: https://github.com/dlang/dub/issues', ansi: :green

          sh.fold 'compiler-download' do
            sh.echo 'Installing compiler and dub', ansi: :yellow

            sh.cmd 'CURL_USER_AGENT="Travis-CI $(curl --version | head -n 1)"'
            sh.cmd <<-'EOT'.gsub(/^              /, '')
              __mirrors=(
                "https://dlang.org/install.sh"
                "https://nightlies.dlang.org/install.sh"
                "https://github.com/dlang/installer/raw/stable/script/install.sh"
              )
              for i in {0..4}; do
                for mirror in "${__mirrors[@]}" ; do
                  if curl -fsSL -A "$CURL_USER_AGENT" --connect-timeout 5 --speed-time 30 --speed-limit 1024 "$mirror" -O ; then
                    break 2
                  fi
                done
                sleep $((1 << i))
              done
              unset __mirrors
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
