require 'travis/build/script/addons/base'
require 'travis/build/script/addons/artifacts/env'
require 'travis/build/script/addons/artifacts/validator'

module Travis
  module Build
    class Script
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

          def before_finish
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
              # Disabled until we have better experience around download links
              # See https://github.com/travis-ci/travis-build/commit/bf2164
              # sh.fold 'artifacts.upload' do
                upload
              # end
              sh.echo 'Done uploading artifacts', ansi: :yellow
            end

            def warn
              validator.errors.each do |error|
                sh.echo error, ansi: :red
              end
            end

            def install
              sh.raw template('install.sh')
            end

            def export
              env.each do |key, value|
                sh.export key, value.inspect, echo: key == 'ARTIFACTS_PATHS'
              end
            end

            def upload
              sh.cmd "artifacts upload #{options}".strip
            end
        end
      end
    end
  end
end
