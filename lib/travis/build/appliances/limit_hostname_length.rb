require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class LimitHostnameLength < Base
        def_delegators :data, :job

        def apply
          sh.echo "Truncating hostname. See https://github.com/travis-ci/travis-ci/issues/5227.", ansi: :yellow
          sh.raw 'sudo hostname "$(hostname 2>/dev/null | cut -d. -f1 | cut -d- -f1-2)-job-' + job[:id].to_s + '" 2>/dev/null', echo: false
          sh.raw 'sed -e "s/^\\(127\\.0\\.0\\.1.*\\)/\\1 $(hostname | cut -d. -f1 | cut -d- -f1-2)-job-' + job[:id].to_s + '/" /etc/hosts | sudo tee /etc/hosts 2>/dev/null', echo: false
          sh.cmd 'hostname', echo: true
        end

        def apply?
          ! data.disable_sudo?
        end
      end
    end
  end
end
