require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixRwkyRedis < Base
        def apply
          command = <<-EOF
          if [[ -d /var/lib/apt/lists && -n $(command -v apt-get) ]]; then
            for f in $(grep -l -r rwky/redis /etc/apt/sources.list.d); do
              sed 's,rwky/redis,rwky/ppa,g' $f > /tmp/${f##**/}
              sudo mv /tmp/${f##**/} /etc/apt/sources.list.d
            done
          fi
          EOF
          sh.cmd command, echo: false
        end
      end
    end
  end
end
