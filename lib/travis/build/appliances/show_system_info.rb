require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class ShowSystemInfo < Base
        def apply
          sh.fold 'system_info' do
            sh.echo 'Build system information', ansi: :yellow
            sh.echo "Build script language: #{data.language}"
            sh.if "-f #{info_file}" do
              sh.cmd "cat #{info_file}"
            end
          end
        end

        private

          def info_file
            '/usr/share/travis/system_info'
          end
      end
    end
  end
end
