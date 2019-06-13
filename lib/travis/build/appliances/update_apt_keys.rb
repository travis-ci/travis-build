require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateAptKeys < Base
        def apply
          sh.if '"$TRAVIS_OS_NAME" == linux' do
            command = <<~KEYUPDATE
            export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
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

            sh.cmd rabbit_key_update, echo: false
          end
        end

        def rabbit_key_update
          <<~EORABBIT
          if [[ ( \"$TRAVIS_DIST\" == trusty || \"$TRAVIS_DIST\" == precise) && -f /etc/init.d/rabbitmq-server ]]; then
            curl -sSL #{key_url('rabbitmq-trusty')} | sudo apt-key add -
          fi &>/dev/null
          EORABBIT
        end

        def key_url(repo)
          tmpl = Travis::Build.config.apt_source_alias_list_key_url_template.to_s.output_safe
          format(
            tmpl.to_s,
            source_alias: repo,
            app_host: Travis::Build::config.app_host.to_s.strip
          ).output_safe
        end
      end
    end
  end
end
