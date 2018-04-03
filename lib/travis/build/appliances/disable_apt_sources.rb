require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableAptSources < Base
        def apply
          sh.raw <<~BASH
            travis_disable_apt_sources() {
              if [[ ! -d /etc/apt/sources.list.d ]]; then
                return
              fi
              local nullglob_state
              nullglob_state="$(shopt -p nullglob)"
              shopt -s nullglob
              for source_file in /etc/apt/sources.list.d/*.list; do
                sudo mv "${source_file}" "${source_file}.save"
              done
              eval "${nullglob_state}"
            }
          BASH
          sh.cmd 'travis_disable_apt_sources', echo: false
        end
      end
    end
  end
end
