require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RestartMysql < Base
        def apply
          sh.cmd 'test -S /var/run/mysqld/mysqld.sock || sudo service mysql restart'
          sh.export 'MYSQL_HOST', '127.0.0.1', echo: false
        end
      end
    end
  end
end

