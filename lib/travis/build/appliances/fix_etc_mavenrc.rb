require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixEtcMavenrc < Base
        def apply
          sh.raw %(test -f /etc/mavenrc && sudo sed -e 's/M2_HOME=\\(.\\+\\)$/M2_HOME=${M2_HOME:-\\1}/' -i'.bak' /etc/mavenrc)
        end
      end
    end
  end
end
