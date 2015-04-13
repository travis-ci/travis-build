require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Transifex < Base
        CLIENT_VERSION = '>=0.11'
        SUPER_USER_SAFE = true
        DEFAULTS = {
          host: 'https://www.transifex.com',
          username: '',
          password: '',
          token: ''
        }.freeze

        def before_script
          run_before
        end

        def after_script
          run_after
        end

        private

          def run_before
            install
            configure
          end

          def run_after
            update
          end

          def install
            sh.echo 'Installing Transifex Client (beta)', ansi: :yellow
            sh.cmd "pip install --user 'transifex-client#{CLIENT_VERSION}'", echo: true
            sh.export 'PATH', '$HOME/.local/bin:$PATH', echo: true
          end

          def configure
            sh.echo 'Writing ~/.transifexrc', ansi: :yellow
            sh.cmd <<-EOF.gsub(/^ {14}/, ''), echo: false
              echo "[#{tx_config[:host]}]
              hostname = #{tx_config[:host]}
              username = ${TX_USER:-#{tx_config[:username]}}
              password = ${TX_PASSWD:-#{tx_config[:password]}}
              token = ${TX_TOKEN:-#{tx_config[:token]}}" > #{Travis::Build::HOME_DIR}/.transifexrc
            EOF
          end

          def update
            sh.cmd "tx push --source --translations --no-interactive", echo: true
          end

          def tx_config
            @tx_config ||= (config[:transifex] || {}).deep_symbolize_keys.reverse_merge(DEFAULTS)
          end
      end
    end
  end
end
