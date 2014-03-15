module Travis
  module Build
    class Script
      module Services
        KNOWN_SERVICES = %w(
          cassandra
          couchdb
          elasticsearch
          hbase-master
          memcached
          mongodb
          mysql
          neo4j
          postgresql
          rabbitmq-server
          redis-server
          riak
          xvfb
        )

        MAP = {
          'hbase'        => 'hbase-master', # for HBase status, see travis-ci/travis-cookbooks#40. MK.
          'memcache'     => 'memcached',
          'neo4j-server' => 'neo4j',
          'rabbitmq'     => 'rabbitmq-server',
          'redis'        => 'redis-server'
        }

        def start_services
          services.each do |name|
            cmd "sudo /usr/local/travis/bin/travis-service #{name} start", timeout: :start_service, assert: false, echo: false
          end
          cmd 'sleep 3', log: false, assert: false if services.any? # give services a moment to start
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
