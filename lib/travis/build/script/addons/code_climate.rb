require 'travis/build/script/addons/base'

module Travis
  module Build
    class Script
      class Addons
        class CodeClimate < Base
          SUPER_USER_SAFE = true

          def after_export
            sh.export 'CODECLIMATE_REPO_TOKEN', token, echo: false if token
          end

          private

            def token
              config[:repo_token]
            end
        end
      end
    end
  end
end

