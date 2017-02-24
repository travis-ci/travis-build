require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RmOraclejdk8Symlink < Base
        def apply
          symlink = '/usr/lib/jvm/java-8-oracle-amd64'
          sh.if "-L #{symlink}" do
            sh.echo "Removing symlink #{symlink}"
            sh.cmd "sudo rm -f #{symlink}", echo: true
            %W(
              #{HOME_DIR}/.jdk_switcher_rc
              /opt/jdk_switcher/jdk_switcher.sh
            ).each do |jdk_switcher|
              sh.if "-f #{jdk_switcher}" do
                sh.echo 'Reload jdk_switcher'
                sh.cmd "source #{jdk_switcher}", echo: true
              end
            end
          end
        end
      end
    end
  end
end
