require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class SetupAptCache < Base
        def apply
          sh.echo 'Setting up APT cache', ansi: :yellow
          sh.cmd %(echo 'Acquire::http { Proxy "#{hosts}"; };' | sudo tee /etc/apt/apt.conf.d/01proxy &> /dev/null)
        end

        def apply?
          data.cache?(:apt) && hosts
        end

        private

          def hosts
            data.hosts && data.hosts[:apt_cache]
          end
      end
    end
  end
end
