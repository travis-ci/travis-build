require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ShowSystemInfo < Base
        def apply
          info_file = '/usr/local/system_info/system_info.log'
          sh.fold 'system_info' do
            sh.echo 'Build System Information', ansi: :yellow
            sh.raw %(test -f #{info_file} && cat #{info_file} || true)
          end
        end
      end
    end
  end
end
