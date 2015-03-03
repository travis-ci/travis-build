require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Transifex < Base
        CLIENT_VERSION = '==0.10'
        SUPER_USER_SAFE = true
        DEFAULTS = {
          project: 'default',
          host: 'https://www.transifex.com',
          debug: false,
          traceback: false,
          pull: {
            all: true,
            force: true,
            minimum_perc: 75,
          }
        }.freeze

        attr_reader :validation_errors

        def before_script
          validate! && run_before
        end

        def after_script
          run_after if valid?
        end

        private

          def run_before
            install
            configure
            propose
          end

          def run_after
            update
          end

          def warn_invalid
            validation_errors.each { |error| sh.echo error, ansi: :red }
          end

          def install
            sh.echo 'Installing Transifex Client (beta)', ansi: :yellow
            sh.cmd "pip install --user transifex-client#{CLIENT_VERSION}", echo: true
            sh.export 'PATH', '$HOME/.local/bin:$PATH', echo: true
          end

          def configure
            sh.cmd "tx init #{tx_init_options}", echo: true
            sh.cmd "tx set #{tx_set_source_options}", echo: true
          end

          def propose
            # TODO: propose translation update
            sh.cmd "tx #{tx_global_options} pull #{tx_first_pull_options}", echo: true
            sh.cmd "tx #{tx_global_options} pull #{tx_second_pull_options}", echo: true
          end

          def update
            # TODO: update upstream translations
            sh.cmd "tx #{tx_global_options} push", echo: true
          end

          def valid?
            !!@valid
          end

          def validate!
            # TODO: define what constitutes a valid configuration, such as relationship to pull requests, disabled
            # branches, etc.
            @valid = true
            @validation_errors = []
            warn_invalid unless @valid
            @valid
          end

          def tx_config
            @tx_config ||= config[:transifex].deep_symbolize_keys.reverse_merge(DEFAULTS)
          end

          def tx_init_options
            @tx_init_options ||= [].tap do |o|
              o << "--host=#{tx_config[:host]}"
            end.join(' ')
          end

          def tx_set_source_options
            @tx_set_source_options ||= [].tap do |o|
              o << '--auto-local'
              o << "--resource=#{tx_dotless_project}.#{tx_dotless_project}-translations"
              o << "#{tx_project}/locale/<lang>/LC_MESSAGES/#{tx_project}.po"
              o << "--source-lang=#{tx_source_lang}"
              o << "--source-file=#{tx_project}/locale/#{tx_project}.pot -t PO"
              o << '--execute'
            end.join(' ')
          end

          def tx_first_pull_options
            @tx_first_pull_options ||= [].tap do |o|
              o << '--all' if tx_config[:pull][:all]
              o << '--force' if tx_config[:pull][:force]
              o << "--minimum-perc=#{tx_config[:pull][:minimum_perc]}"
            end.join(' ')
          end

          def tx_second_pull_options
            @tx_second_pull_options ||= [].tap do |o|
              o << '--force' if tx_config[:pull][:force]
            end
          end

          def tx_global_options
            @tx_global_options ||= [].tap do |o|
              o << '--debug' if tx_config[:debug]
              o << '--traceback' if tx_config[:traceback]
            end.join(' ')
          end

          def tx_project
            tx_config[:project]
          end

          def tx_dotless_project
            @tx_dotless_project ||= tx_project.gsub(/\./, '')
          end
      end
    end
  end
end
