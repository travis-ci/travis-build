require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ReenableIpv6 < Base
        def apply
          sh.if "-f /etc/sysctl.d/99-travis-disable-ipv6" do
            sh.cmd "sudo sysctl net.ipv6.conf.all.disable_ipv6=0", echo: true
            sh.cmd "sudo sysctl net.ipv6.conf.default.disable_ipv6=0", echo: true
            sh.cmd "cat /proc/sys/net/ipv6/conf/all/disable_ipv6", echo: true
            sh.cmd "cat /proc/sys/net/ipv6/conf/default/disable_ipv6", echo: true
          end
        end

        def apply?
          data[:enable_ipv6] && !data.disable_sudo?
        end
      end
    end
  end
end
