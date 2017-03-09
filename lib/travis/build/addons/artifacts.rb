require 'travis/build/addons/base'
require 'travis/build/addons/artifacts/env'
require 'travis/build/addons/artifacts/validator'

module Travis
  module Build
    class Addons
      class Artifacts < Base
        SUPER_USER_SAFE = true
        TEMPLATES_PATH = File.expand_path('templates', __FILE__.sub('.rb', ''))

        attr_reader :env, :options, :validator

        def initialize(*)
          super
          @options = config.delete(:options)
          @validator = Validator.new(data, config)
          @env = Env.new(data, config)
        end

        def after_header
          sh.raw template('artifacts.sh')
        end

        def after_after_script
          sh.newline
          validator.valid? ? run : warn
          sh.newline
        end

        private

          def run
            sh.echo 'Uploading Artifacts (BETA)', ansi: :yellow
            sh.fold 'artifacts.setup' do
              install
              export
            end
            default_env_keys.each { |key| ensure_env_set(key) }
            upload
            sh.echo 'Done uploading artifacts', ansi: :yellow
          end

          def export
            env.each do |key, value|
              sh.export key, value.inspect, echo: key == 'ARTIFACTS_PATHS'
            end
          end

          def install
            sh.cmd 'travis_artifacts_install'
          end

          def default_env_keys
            Travis::Build::Addons::Artifacts::Env::DEFAULT.keys
          end

          def ensure_env_set(key)
            env_key = "ARTIFACTS_#{key.to_s.upcase}"
            sh.if(%(-z "${#{env_key}}")) do
              sh.export(
                env_key,
                Travis::Build::Addons::Artifacts::Env::DEFAULT[key],
                echo: env_key == 'ARTIFACTS_PATHS'
              )
            end
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
