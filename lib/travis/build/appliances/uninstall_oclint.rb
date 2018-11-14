require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UninstallOclint < Base
        def apply
          sh.if "$(command -v brew)" do
            sh.cmd "brew cask uninstall oclint &>/dev/null", assert: false
            sh.if "$? == 0" do
              sh.echo "Uninstalled oclint to prevent interference with other packages."
              sh.echo "If you need oclint, you must explicitly install it."
            end
            sh.newline
          end
        end
      end
    end
  end
end
