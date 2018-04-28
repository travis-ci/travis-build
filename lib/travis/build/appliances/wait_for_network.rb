require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class WaitForNetwork < Base
        FUNC = <<~func
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
        func

        def apply
          sh.raw FUNC
          sh.cmd cmd.untaint, echo: false
        end

        private

          def cmd
            "travis_wait_for_network #{retries} #{quote(urls).join(' ')}"
          end

          def urls
            urls = Travis::Build.config.network.check_urls
            args = { app_host: app_host, job_id: data.job[:id], repo: data.slug }
            urls.map { |tmpl| tmpl % args }
          end

          def quote(strs)
            strs.map { |str| "'#{str}'" }
          end

          def retries
            Integer(Travis::Build.config.network.wait_retries)
          end
      end
    end
  end
end
