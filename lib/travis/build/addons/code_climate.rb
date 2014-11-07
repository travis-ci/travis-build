require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class CodeClimate < Base
        SUPER_USER_SAFE = true

        def before_before_script
          sh.export 'CODECLIMATE_REPO_TOKEN', token, echo: false if token
        end

        private

          def token
            config[:repo_token]
          rescue
            false
          end
      end
    end
  end
end
