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
          set_retries = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            cat <<-EOS | sudo tee /etc/apt/apt.conf.d/99apt
Acquire {
  ForceIPv4 "1";
  Retries "5";
  https {
    Timeout "30";
  };
};
EOS
          fi
          EOF
          sh.cmd set_retries
        end
      end
    end
  end
end