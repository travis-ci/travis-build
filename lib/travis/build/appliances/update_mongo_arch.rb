require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateMongoArch < Base
        def apply
          command = <<-EOF
            if command -v lsb_release &>/dev/null; then
              shopt -s nullglob
              for f in /etc/apt/sources.list.d/mongodb-*.list; do
                grep -vq arch=amd64 "$f" && sudo sed -i 's/^deb /deb [arch=amd64] /' "$f"
              done
              shopt -u nullglob
            fi
            EOF
          sh.cmd command, echo: false, assert: false, sudo: false
        end
      end
    end
  end
end
