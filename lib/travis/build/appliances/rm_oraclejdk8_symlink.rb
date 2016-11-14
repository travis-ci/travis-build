require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RmOraclejdk8Symlink < Base
        def apply
          symlink = "/usr/lib/jvm/java-8-oracle-amd64"

          sh.if "-L #{symlink}" do
            sh.echo "Removing symlink #{symlink}"
            sh.cmd "sudo rm -f #{symlink}", echo: true
            sh.echo "Reload jdk_switcher"
            sh.cmd "source $HOME/.jdk_switcher_rc", echo: true
          end
        end

      end
    end
  end
end

