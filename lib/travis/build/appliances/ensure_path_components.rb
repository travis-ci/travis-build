require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class EnsurePathComponents < Base

        COMPONENTS = [
          '$(yarn global bin)'
        ]

        def apply
          COMPONENTS.each do |pc|
            sh.cmd <<-EOF
pc=#{pc}
if [[ -z $(echo :$PATH: | grep :$pc:) ]]; then export PATH=$PATH:$pc; fi
unset pc
            EOF
          end
        end
      end
    end
  end
end
