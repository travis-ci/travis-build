require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class HomePaths < Base
        def apply
          # XXX Ensure $PATH is prepended with a few entries to ease development in
          # container-based infrastructure.
          sh.cmd <<-EOF.gsub(/^ {12}/, '')
            # apply :home_paths
            for path_entry in $HOME/.local/bin $HOME/bin ; do
              if [[ ${PATH%%:*} != $path_entry ]] ; then
                export PATH="$path_entry:$PATH"
              fi
            done
          EOF
        end
      end
    end
  end
end
