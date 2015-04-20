require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RestartMysql < Base
        def apply
          sh.cmd '(ls /var/run/mysqld/mysqld.sock >& /dev/null) || sudo service mysql restart'
        end
      end
    end
  end
end

