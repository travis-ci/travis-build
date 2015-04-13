require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Transifex < Base
        CLIENT_VERSION = '>=0.11'
        SUPER_USER_SAFE = true
        DEFAULTS = {
          hostname: 'https://www.transifex.com',
          username: '',
          password: '',
          token: '',
          auto_push: 'enabled'
        }.freeze

        def before_script
          install
          configure
        end

        def after_success
          source_push unless tx_config[:auto_push] == 'disabled'
        end

        private

          def install
            sh.echo 'Installing Transifex Client (beta)', ansi: :yellow
            sh.cmd "pip install --user 'transifex-client#{CLIENT_VERSION}'", echo: true
            sh.export 'PATH', '$HOME/.local/bin:$PATH', echo: true
          end

          def configure
            sh.echo 'Writing ~/.transifexrc', ansi: :yellow
            sh.cmd <<-EOF.gsub(/^ {14}/, ''), echo: false
              echo "[${TX_HOSTNAME:-#{tx_config[:hostname]}}]
              hostname = ${TX_HOSTNAME:-#{tx_config[:hostname]}}
              username = ${TX_USERNAME:-#{tx_config[:username]}}
              password = ${TX_PASSWORD:-#{tx_config[:password]}}
              token = ${TX_TOKEN:-#{tx_config[:token]}}" > #{Travis::Build::HOME_DIR}/.transifexrc
            EOF
          end

          def source_push
            sh.echo 'Pushing to Transifex', ansi: :yellow
            sh.cmd 'tx push --source --no-interactive', echo: true
          end

          def tx_config
            @tx_config ||= DEFAULTS.merge((config || {}).deep_symbolize_keys)
          end
      end
    end
  end
end
