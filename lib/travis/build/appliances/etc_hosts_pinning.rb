require 'shellwords'
require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class EtcHostsPinning < Base
        def apply
          Travis::Build.config.etc_hosts_pinning.to_s.output_safe.split(',').each do |etchostsline|
            sh.raw %(echo #{Shellwords.escape(etchostsline)} | sudo tee -a /etc/hosts &>/dev/null)
          end
        end

        def apply?
          super && !Travis::Build.config.etc_hosts_pinning.to_s.strip.empty?
        end
      end
    end
  end
end
