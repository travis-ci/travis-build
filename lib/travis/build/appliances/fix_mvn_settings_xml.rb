require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixMvnSettingsXml < Base
        def apply
          sh.cmd %(test -f ~/.m2/settings.xml && sed -i.bak -e 's|https://nexus.codehaus.org/snapshots/|https://oss.sonatype.org/content/repositories/codehaus-snapshots/|g' ~/.m2/settings.xml)
        end
      end
    end
  end
end
