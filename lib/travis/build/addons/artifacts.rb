require 'travis/build/addons/base'
require 'travis/build/addons/artifacts/env'
require 'travis/build/addons/artifacts/validator'

module Travis
  module Build
    class Addons
      class Artifacts < Base
        SUPER_USER_SAFE = true

        attr_reader :env, :options, :validator

        def initialize(*)
          super
          @options = config.delete(:options)
          @validator = Validator.new(data, config)
          @env = Env.new(data, config)
        end

        def after_header
          sh.raw bash('travis_artifacts_install')
        end

        def after_after_script
          sh.newline
          validator.valid? ? run : warn
          sh.newline
        end

        private

          def run
            sh.echo 'Uploading Artifacts', ansi: :yellow
            sh.fold 'artifacts.setup' do
              install
              export
            end
            upload
            sh.echo 'Done uploading artifacts', ansi: :yellow
          end

          def export
            env.each do |key, value|
              if env.force?(key)
                sh.export(key, value.inspect, echo: false)
                next
              end

              sh.if(%(-z "${#{key}}")) do
                sh.export key, value.inspect, echo: key == 'ARTIFACTS_PATHS'
              end
            end
          end

          def install
            sh.cmd 'travis_artifacts_install'
          end

          def upload
            sh.cmd "artifacts upload #{options}".strip, echo: true
          end

          def warn
            validator.errors.each do |error|
              sh.echo error, ansi: :red
            end
          end
      end
    end
  end
end
