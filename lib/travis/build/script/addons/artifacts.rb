require 'travis/build/script/addons/artifacts/env'
require 'travis/build/script/addons/artifacts/validator'

module Travis
  module Build
    class Script
      module Addons
        class Artifacts
          include Helpers

          TEMPLATES_PATH = File.expand_path('templates', __FILE__.gsub('.rb', ''))

          SUPER_USER_SAFE = true

          attr_accessor :sh, :data, :env, :options, :validator

          def initialize(script, config)
            @sh = script.sh
            @data = script.data
            @options = config.delete(:options)
            @validator = Validator.new(data, config)
            @env = Env.new(data, config)
          end

          def after_script
            sh.newline
            validator.valid? ? run : warn
            sh.newline
          end

          private

            def run
              sh.echo 'Uploading Artifacts (BETA)', ansi: :green
              sh.fold 'artifacts.setup' do
                install
                export
              end
              sh.fold 'artifacts.upload' do
                upload
              end
              sh.echo 'Done uploading artifacts', ansi: :green
            end

            def warn
              validator.errors.each do |error|
                sh.echo error, ansi: :red
              end
            end

            def install
              # TODO should be ported to sh calls
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
