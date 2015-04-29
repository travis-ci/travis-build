require 'travis/build/appliances/checkout'
require 'travis/build/appliances/deprecations'
require 'travis/build/appliances/disable_sudo'
require 'travis/build/appliances/env'
require 'travis/build/appliances/fix_etc_hosts'
require 'travis/build/appliances/fix_ps4'
require 'travis/build/appliances/fix_resolv_conf'
require 'travis/build/appliances/put_localhost_first'
require 'travis/build/appliances/services'
require 'travis/build/appliances/setup_apt_cache'
require 'travis/build/appliances/show_system_info'
require 'travis/build/appliances/validate'

module Travis
  module Build
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
