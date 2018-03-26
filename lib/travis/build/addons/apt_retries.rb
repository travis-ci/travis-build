require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class AptRetries < Base
        SUPER_USER_SAFE = true

        def before_configure?
          config
        end

        def before_configure
          sh.echo "Configuring default apt-get retries", ansi: :yellow
          sh.raw <<~EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            cat <<-EOS > 99-travis-build-retries
          Acquire {
            ForceIPv4 "1";
            Retries "5";
            https {
              Timeout "30";
            };
          };
          EOS
            sudo mv 99-travis-build-retries /etc/apt/apt.conf.d
          fi
          EOF
        end
      end
    end
  end
end
