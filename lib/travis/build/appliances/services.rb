require 'shellwords'
require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Services < Base
        SERVICES = {
          'hbase'        => 'hbase-master', # for HBase status, see travis-ci/travis-cookbooks#40. MK.
          'memcache'     => 'memcached',
          'neo4j-server' => 'neo4j',
          'rabbitmq'     => 'rabbitmq-server',
          'redis'        => 'redis-server'
        }

        def apply
          sh.fold 'services' do
            services.each do |name|
              service_apply_method = "apply_#{name}"
              if respond_to?(service_apply_method)
                send(service_apply_method)
                next
              end
              sh.cmd "sudo service #{name.shellescape} start", assert: false, echo: true, timing: true
            end
            sh.raw 'sleep 3'
          end
        end

        def apply?
          services.any?
        end

        def apply_mongodb
          sh.if "$(lsb_release -cs) != 'precise'" do
            sh.cmd 'sudo service mongod start', assert: false, echo: true, timing: true
          end
          sh.else do
            sh.cmd 'sudo service mongodb start', assert: false, echo: true, timing: true
          end
        end

        def apply_mysql
          sh.raw <<~BASH
            travis_mysql_ping() {
              mysql &>/dev/null <<<'SHOW VARIABLES like "%version%"'
            }
          BASH
          sh.cmd 'sudo service mysql start', assert: false, echo: true, timing: true
          sh.cmd 'travis_wait travis_mysql_ping', assert: false, echo: false, timing: false
        end

        private

          def services
            @services ||= Array(config[:services]).map do |name|
              normalize(name)
            end
          end

          def normalize(name)
            name = name.to_s.downcase
            SERVICES[name] ? SERVICES[name] : name
          end
      end
    end
  end
end
