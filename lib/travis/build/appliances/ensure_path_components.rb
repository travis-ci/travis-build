require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class EnsurePathComponents < Base

        COMPONENTS = [
          '$(yarn global bin | grep /)'
        ]

        def apply
          COMPONENTS.each do |pc|
            sh.cmd <<-EOF
pc=#{pc}
if [[ -n $pc && :$PATH: =~ :$pc: ]]; then export PATH=$PATH:$pc; fi
unset pc
            EOF
          end
        end
      end
    end
  end
end
