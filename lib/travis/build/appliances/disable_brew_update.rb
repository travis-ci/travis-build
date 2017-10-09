require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableBrewUpdate < Base
        def apply
          disable_update = %q{
if [ $(command -v sw_vers) ]; then
  echo "Disabling Homebrew auto update. If your Homebrew package requires Homebrew DB be up to date, please run \\`brew update\\` explicitly."
  export HOMEBREW_NO_AUTO_UPDATE=1
fi
          }
          sh.cmd disable_update, ansi: :yellow, echo: true
        end
      end
    end
  end
end
