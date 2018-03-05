require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class WaitForNetwork < Base
        def apply

          sh.raw <<~BASHSNIP
            travis_wait_for_network() {
              local job_id="${1}"
              local repo="${2}"
              local count=1
              local url="http://#{app_host}/empty.txt?job_id=${job_id}&repo=${repo}"

              set -o xtrace
              while [[ "${count}" -lt 20 ]]; do
                if travis_download "${url}?count=${count}" /dev/null; then
                  echo -e "${ANSI_GREEN}Network availability confirmed.${ANSI_RESET}"
                  set +o xtrace
                  return
                fi
                count=$((count + 1))
                sleep 1
              done

              set +o xtrace
              echo -e "${ANSI_RED}Timeout waiting for network availability.${ANSI_RESET}"
            }
          BASHSNIP

          sh.cmd "travis_wait_for_network '#{data.job[:id]}' '#{data.slug}'",
                 echo: false
        end
      end
    end
  end
end
