module Travis
  module Build
    class Addons
      class SystemInfo < Base
        SUPER_USER_SAFE = true

        def after_configure
          sh.if "-f #{info_file}" do
            sh.fold 'system_info.ext' do
              sh.echo 'Extended build system information', ansi: :yellow
              sh.cmd "cat #{info_file}", echo: false
            end
          end
        end

        def info_file
          '/usr/share/travis/system_info'
        end
      end
    end
  end
end
