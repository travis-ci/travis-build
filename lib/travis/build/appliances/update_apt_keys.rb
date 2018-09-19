require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateAptKeys < Base
        def apply
          sh.if '"$TRAVIS_OS_NAME" == linux' do
            command = <<~KEYUPDATE
            apt-key adv --list-public-keys --with-fingerprint --with-colons |
              awk -F: '
                  $1=="pub" && $2~/^[er]$/ { state="expired" }
                  $1=="fpr" && state == "expired" {
                    out = sprintf("%s %s", out, $(NF -1))
                    state="valid"
                  }
                  END {
                    if (length(out)>0)
                      printf "sudo apt-key adv --recv-keys --keyserver ha.pool.sks-keyservers.net %s", out
                  }
                ' |
              bash &>/dev/null
            KEYUPDATE
            sh.cmd command, echo: false
          end
        end
      end
    end
  end
end

