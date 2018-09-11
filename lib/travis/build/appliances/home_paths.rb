require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class HomePaths < Base
        def apply
          # XXX Ensure $PATH is prepended with a few entries to ease development in
          # container-based infrastructure.
          sh.cmd <<~BASH
            # apply :home_paths
            for path_entry in ${TRAVIS_HOME}/.local/bin ${TRAVIS_HOME}/bin ; do
              if [[ ${PATH%%:*} != ${path_entry} ]] ; then
                export PATH="${path_entry}:$PATH"
              fi
            done
          BASH
        end
      end
    end
  end
end
