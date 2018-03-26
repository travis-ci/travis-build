require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AptGetUpdate < Base
        def apply
          retry_under = Travis::Build.config.apt.retries.percentage.to_i || 0 # if under this, we add retry config
          if rand(100) < retry_under
            set_retries = <<-EOF
if [[ ! -f /etc/apt/apt.conf.d/99apt ]]; then
  echo -e "${ANSI_YELLOW}Setting retries for apt-get${ANSI_RESET}"
  if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
    cat <<- EOS > 99apt
Acquire {
  ForceIPv4 "1";
  Retries "5";
  https {
    Timeout "30";
  };
};
EOS
    sudo mv 99apt /etc/apt/apt.conf.d
  fi
fi
            EOF
            sh.cmd set_retries
          end

          command = <<-EOF
            sudo rm -rf /var/lib/apt/lists/*
            sudo apt-get update -qq 2>&1 >/dev/null
          EOF
          sh.cmd command
        end
      end
    end
  end
end
