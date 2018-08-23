require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class WaitForNetwork < Base
        def apply

          sh.raw <<~BASHSNIP
            travis_wait_for_network() {
              local wait_retries="${1}"
              local count=0
              shift
              local urls=("${@}")

              while [[ "${count}" -lt "${wait_retries}" ]]; do
                local confirmed=0
                for url in "${urls[@]}"; do
                  if travis_download "${url}" /dev/null; then
                    confirmed=$((confirmed + 1))
                  fi
                done

                if [[ "${#urls[@]}" -eq "${confirmed}" ]]; then
                  echo -e "${ANSI_GREEN}Network availability confirmed.${ANSI_RESET}"
                  return
                fi

                count=$((count + 1))
                sleep 1
              done

              echo -e "${ANSI_RED}Timeout waiting for network availability.${ANSI_RESET}"
            }
          BASHSNIP

          sh.cmd %W[
            travis_wait_for_network
              '#{wait_retries}' '#{check_urls.join("' '")}'
          ].join(' ').untaint, echo: false
          sh.echo
        end

        private def check_urls
          @check_urls ||= Travis::Build.config.network.check_urls.map do |tmpl|
            tmpl % {
              app_host: app_host,
              job_id: data.job[:id],
              repo: data.slug
            }
          end
        end

        private def wait_retries
          @wait_retries ||= Integer(Travis::Build.config.network.wait_retries)
        end
      end
    end
  end
end
