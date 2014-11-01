require 'shellwords'

module Travis
  module Build
    class Script
      module Services
        MAP = {
          'hbase'        => 'hbase-master', # for HBase status, see travis-ci/travis-cookbooks#40. MK.
          'memcache'     => 'memcached',
          'neo4j-server' => 'neo4j',
          'rabbitmq'     => 'rabbitmq-server',
          'redis'        => 'redis-server'
        }

        def start_services
          services.each do |name|
            sh.cmd "sudo service #{name.shellescape} start", assert: false
          end
          sh.raw 'sleep 3' if services.any? # give services a moment to start
        end

        def services
          @services ||= Array(config[:services]).map do |name|
            normalize_service(name)
          end
        end

        def normalize_service(name)
          name = name.to_s.downcase
          MAP[name] ? MAP[name] : name
        end
      end
    end
  end
end
