require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class EnsurePathComponents < Base

        COMPONENTS = [
          '$(yarn global bin 2>/dev/null | grep /)'
        ]

        def apply
          COMPONENTS.each do |pc|
            sh.cmd <<~EOF
              [[ -n "#{pc}" && ! :$PATH: =~ :#{pc}: ]] && export PATH="$PATH:#{pc}"
            EOF
          end
        end
      end
    end
  end
end
