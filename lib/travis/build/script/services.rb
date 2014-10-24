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
        VERSION_COMMANDS = {
          'couchdb'         => 'couchdb -V | head -1',
          # FIXME: curl'ing for elasticsearch version info does not work reliably (?)
          # 'elasticsearch'   => 'curl -s localhost:9200',
          # FIXME: hbase is not installed anymore (?)
          # 'hbase-master'    => 'hbase version',
          'memcached'       => 'memcached -h | head -1',
          'mongodb'         => 'mongod --version',
          'mysql'           => 'mysqld --version 2>/dev/null',
          # FIXME: neo4j info does not work reliably (?)
          # 'neo4j'           => 'neo4j info | grep INSTANCE',
          'postgresql'      => 'psql -U postgres template1 -t -A -c \'select version()\'',
          'rabbitmq-server' => 'sudo rabbitmqctl status | grep rabbit,',
          'redis-server'    => 'redis-server --version',
          'riak'            => 'riak version',
        }

        def start_services
          services.each do |name|
            cmd "sudo service #{name.shellescape} start", assert: false
            announce_service_version(name)
          end
          raw 'sleep 3' if services.any? # give services a moment to start
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

        def announce_service_version(name)
          return unless VERSION_COMMANDS.key?(name)
          cmd VERSION_COMMANDS.fetch(name), assert: false
        end
      end
    end
  end
end
