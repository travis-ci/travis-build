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
          auto_push: {
            enabled: true,
            job: 1,
            branches: %w(master)
          }
        }.freeze

        def before_before_script
          install
          configure
        end

        def after_after_success
          sh.fold 'transifex.push' do
            if tx_config[:auto_push][:enabled]
              source_push
            else
              sh.echo 'Skipping push to Transifex', ansi: :yellow
            end
          end
        end

        private

          def install
            sh.fold 'transifex.install' do
              sh.echo 'Installing Transifex Client (beta)', ansi: :yellow
              sh.cmd "pip install --user 'transifex-client#{CLIENT_VERSION}'", echo: true
              sh.export 'PATH', '$HOME/.local/bin:$PATH', echo: true
            end
          end

          def configure
            sh.echo "Writing #{tx_rc_path}", ansi: :yellow
            sh.cmd <<-EOF.gsub(/^ {14}/, ''), echo: false
              echo "[${TX_HOSTNAME:-#{tx_config[:hostname]}}]
              hostname = ${TX_HOSTNAME:-#{tx_config[:hostname]}}
              username = ${TX_USERNAME:-#{tx_config[:username]}}
              password = ${TX_PASSWORD:-#{tx_config[:password]}}
              token = ${TX_TOKEN:-#{tx_config[:token]}}" > #{tx_rc_path}
            EOF
          end

          def source_push
            sh.if "$TRAVIS_JOB_NUMBER =~ '\\.#{tx_config[:auto_push][:job]}$'" do
              sh.if "$TRAVIS_BRANCH =~ '^(#{tx_config[:auto_push][:branches].join('|')})$'" do
                sh.echo 'Pushing to Transifex', ansi: :yellow
                sh.cmd 'tx push --source --no-interactive', echo: true
              end
            end
          end

          def tx_config
            @tx_config ||= DEFAULTS.deep_merge((config || {}).deep_symbolize_keys)
          end

          def tx_rc_path
            @tx_rc_path ||= "#{Travis::Build::HOME_DIR}/.transifexrc"
          end
      end
    end
  end
end
