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
              sh.cmd "sudo service #{name.shellescape} start", assert: false, echo: true, timing: true
            end
            sh.raw 'sleep 3'
          end
        end

        def apply?
          services.any?
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
