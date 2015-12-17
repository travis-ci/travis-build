require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class LimitHostnameLength < Base
        def_delegators :data, :job

        def apply
          sh.raw 'sudo hostname "$(hostname | cut -d. -f1 | cut -d- -f1-2)-job-' + job[:id].to_s + '"', echo: true
          sh.raw 'sed -e "s/^\\(127\\.0\\.0\\.1.*\\)/\\1 $(hostname -f | cut -d. -f1 | cut -d- -f1-2)-job-' + job[:id].to_s + '/" /etc/hosts | sudo tee /etc/hosts', echo: true
        end
      end
    end
  end
end
