require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ShowSystemInfo < Base
        def apply
          info_file = '/usr/share/travis/sytem_info'
          sh.fold 'system_info' do
            sh.echo 'Build System Information', ansi: :yellow
            sh.raw %(test -f #{info_file} && cat #{info_file} || true)
          end
        end
      end
    end
  end
end
