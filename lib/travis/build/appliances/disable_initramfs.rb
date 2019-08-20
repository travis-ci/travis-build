require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DisableInitramfs < Base
        def apply
          sh.raw "if [ ! $(uname|egrep 'Darwin|FreeBSD') ]; then echo update_initramfs=no | sudo tee -a /etc/initramfs-tools/update-initramfs.conf > /dev/null; fi"
        end
      end
    end
  end
end
