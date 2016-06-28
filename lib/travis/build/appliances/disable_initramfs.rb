require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableInitramfs < Base
        def apply
          sh.raw "echo update_initramfs=no | sudo tee -a /etc/initramfs-tools/update-initramfs.conf > /dev/null"
        end
      end
    end
  end
end
