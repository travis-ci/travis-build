require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixMvnSettingsXml < Base
        def apply
          sh.if "-f ~/.m2/settings.xml" do
            sh.cmd %(sed -i$([ "$TRAVIS_OS_NAME" == osx ] && echo " ").bak1 -e 's|https://nexus.codehaus.org/snapshots/|https://oss.sonatype.org/content/repositories/codehaus-snapshots/|g' ~/.m2/settings.xml), echo: false, assert: false, timing: false
            sh.cmd %(sed -i$([ "$TRAVIS_OS_NAME" == osx ] && echo " ").bak2 -e 's|https://repository.apache.org/releases/|https://repository.apache.org/content/repositories/releases/|g' ~/.m2/settings.xml), echo: false, assert: false, timing: false
          end
        end
      end
    end
  end
end
