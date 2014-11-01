require 'shellwords'
require 'travis/build/script/addons/base'

module Travis
  module Build
    class Script
      module Addons
        class Postgresql < Base
          SUPER_USER_SAFE = true

          def after_pre_setup
            sh.fold 'postgresql' do
              sh.export "PATH", "/usr/lib/postgresql/#{version}/bin:$PATH", echo: false
              sh.echo "Starting PostgreSQL v#{version}", ansi: :yellow
              sh.cmd "service postgresql stop", assert: false, sudo: true
              sh.cmd "service postgresql start #{version}", assert: false, sudo: true
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
end
