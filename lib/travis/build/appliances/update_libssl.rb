require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateLibssl < Base
        def apply
          sh.if "-n $(command -v lsb_release) && $(lsb_release -cs) = 'precise'" do
            sh.fold "update_libssl1.0.0" do
              sh.cmd "apt-get install ca-certificates libssl1.0.0", sudo: true, echo: true
            end
          end
        end

        def apply?
          super && data.disable_sudo?
        end
      end
    end
  end
end
