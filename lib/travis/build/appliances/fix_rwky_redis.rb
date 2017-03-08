require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixRwkyRedis < Base
        def apply
          list_file = '/etc/apt/sources.list.d/rwky-redis.list'
          sh.if "-f #{list_file}" do
            sh.cmd "sudo sed -i 's,rwky/redis,rwky/ppa,g' #{list_file}", echo: false
          end
        end
      end
    end
  end
end
