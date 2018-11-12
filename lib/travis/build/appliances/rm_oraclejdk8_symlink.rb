require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RmOraclejdk8Symlink < Base
        def apply
          symlink = '/usr/lib/jvm/java-8-oracle-amd64'
          sh.if "-L #{symlink}" do
            sh.cmd "sudo rm -f #{symlink}", echo: false
            %W(
              ${TRAVIS_HOME}/.jdk_switcher_rc
              /opt/jdk_switcher/jdk_switcher.sh
            ).each do |jdk_switcher|
              sh.if "-f #{jdk_switcher}" do
                sh.cmd "source #{jdk_switcher}", echo: false
              end
            end
          end
        end
      end
    end
  end
end
