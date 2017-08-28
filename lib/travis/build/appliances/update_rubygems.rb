require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateRubygems < Base
        RUBYGEMS_BASELINE_VERSION='2.6.13'
        def apply
          sh.cmd "cat >$HOME/.rvm/hooks/after_use <<EORVMHOOK
vers2int() {
  printf '1%03d%03d%03d%03d' $(echo \"$1\" | tr '.' ' ')
}

if [[ $(vers2int `gem --version`) -lt $(vers2int \"#{RUBYGEMS_BASELINE_VERSION}\") ]]; then
  gem update --system
fi
EORVMHOOK
"
          sh.cmd "chmod +x $HOME/.rvm/hooks/after_use"
        end
      end
    end
  end
end
