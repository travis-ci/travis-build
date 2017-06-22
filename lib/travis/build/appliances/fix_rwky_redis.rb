require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixRwkyRedis < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            RWKY_REDIS_PURGE_NEEDED=
            for f in $(grep -l rwky/redis /etc/apt/sources.list.d/*); do
              sed 's,rwky/redis,rwky/ppa,g' $f > /tmp/${f##**/}
              sudo mv /tmp/${f##**/} /etc/apt/sources.list.d
              RWKY_REDIS_PURGE_NEEDED=1
            done
            if [[ $RWKY_REDIS_PURGE_NEEDED ]]; then
              sudo rm -rf /var/lib/apt/lists/*
              sudo apt-get update -qq &>/dev/null
            fi
          fi
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end
