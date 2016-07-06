require 'shellwords'
require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class EtcHostsPinning < Base
        def apply
          ENV['ETC_HOSTS_PINNING'].split(',').each do |etchostsline|
            sh.raw %(echo #{Shellwords.escape(etchostsline.untaint)} | sudo tee -a /etc/hosts)
          end
        end

        def apply?
          ENV.key?('ETC_HOSTS_PINNING')
        end
      end
    end
  end
end
