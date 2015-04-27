require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class RestartMysql < Base
        def apply
          sh.cmd 'test -S /var/run/mysqld/mysqld.sock || sudo service mysql restart'
        end
      end
    end
  end
end

