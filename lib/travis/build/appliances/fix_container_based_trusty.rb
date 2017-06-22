# frozen_string_literal: true

require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class FixContainerBasedTrusty < Base
        REDIS_INIT = '/etc/init.d/redis-server'
        private_constant :REDIS_INIT

        def apply
          sh.if sh_is_linux? do
            sh.if sh_is_trusty? do
              patch_redis_init
            end
          end
        end

        def apply?
          true
        end

        private

        def sh_is_linux?
          '$(uname) = Linux'
        end

        def sh_is_trusty?
          '$(lsb_release -sc 2>/dev/null) = trusty'
        end

        def patch_redis_init
          sh.if "-f #{REDIS_INIT}" do
            sh.echo 'Patching redis-server init script', ansi: :yellow
            sh.raw(
              %(sudo sed -i '/ulimit -n/s/ulimit.*/echo noulimit/g' #{REDIS_INIT})
            )
          end
        end
      end
    end
  end
end
