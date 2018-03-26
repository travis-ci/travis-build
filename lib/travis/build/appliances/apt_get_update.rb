require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          retry_under = Travis::Build.config.apt.retries.percentage.to_i || 0 # if under this, we add retry config
          if rand(100) < retry_under
            sh.if "-f /etc/apt/apt.conf.d/99apt" do
              sh.echo "Setting retries for apt-get", ansi: :yellow
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
              EOF
              sh.cmd set_retries
            end
          end

          command = <<-EOF
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt-get update -qq 2>&1 >/dev/null
          fi
          EOF
          sh.cmd command
        end
      end
    end
  end
end
