module Travis
  module Build
    class Script
      module Addons
        class CodeClimate
          SUPER_USER_SAFE = true

          def initialize(sh, config)
            @sh = sh
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            if @config[:repo_token]
              @sh.set 'CODECLIMATE_REPO_TOKEN', @config[:repo_token], echo: false
            end
          end
        end
      end
    end
  end
end

