require 'travis/build/script/appliances/checkout'
require 'travis/build/script/appliances/deprecations'
require 'travis/build/script/appliances/disable_sudo'
require 'travis/build/script/appliances/env'
require 'travis/build/script/appliances/fix_etc_hosts'
require 'travis/build/script/appliances/fix_ps4'
require 'travis/build/script/appliances/fix_resolv_conf'
require 'travis/build/script/appliances/services'
require 'travis/build/script/appliances/setup_apt_cache'
require 'travis/build/script/appliances/validate'

module Travis
  module Build
    class Script
      module Appliances
        def apply(name)
          app = appliance(name)
          app.apply if app.apply?
        end

        def appliance(name)
          Appliances.const_get(name.to_s.camelize).new(self)
        end
      end
    end
  end
end
