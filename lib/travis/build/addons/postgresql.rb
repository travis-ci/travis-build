require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Postgresql < Base

        include Template

        SUPER_USER_SAFE = true
        TEMPLATES_PATH = File.expand_path('../../templates', __FILE__)

        def after_prepare
          sh.if '"$TRAVIS_OS_NAME" != linux' do
            sh.echo "Addon PostgreSQL is not supported on #{data[:config][:os]}", ansi: :red
          end
          sh.else do
            sh.fold 'postgresql' do
              sh.raw(template('postgresql.sh', version: nil), echo: false, timing: false)
              sh.cmd 'travis_setup_postgresql', echo: true, timing: true
            end
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
