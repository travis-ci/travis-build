require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixRwkyRedis < Base
        def apply
          command = <<-EOF
            sudo rm -rf /var/lib/apt/lists/*
            for f in $(grep -l rwky/redis /etc/apt/sources.list.d/*); do
              sed 's,rwky/redis,rwky/ppa,g' $f > /tmp/${f##**/}
              sudo mv /tmp/${f##**/} /etc/apt/sources.list.d
            done
            sudo apt-get update -qq
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end
