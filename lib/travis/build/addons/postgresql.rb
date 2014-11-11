require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Postgresql < Base
        SUPER_USER_SAFE = true

        def after_prepare
          sh.fold 'postgresql' do
            sh.export "PATH", "/usr/lib/postgresql/#{version}/bin:$PATH", echo: false
            sh.echo "Starting PostgreSQL v#{version}", ansi: :yellow
            sh.cmd "service postgresql stop", assert: false, sudo: true, echo: true, timing: true
            sh.cmd "service postgresql start #{version}", assert: false, sudo: true, echo: true, timing: true
          end
        end

        private

          def version
            config.to_s.shellescape
          end
      end
    end
  end
end
