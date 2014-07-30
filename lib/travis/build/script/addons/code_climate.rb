module Travis
  module Build
    class Script
      module Addons
        class CodeClimate
          SUPER_USER_SAFE = true

          attr_reader :sh, :config

          def initialize(script, config)
            @sh = script.sh
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            if config[:repo_token]
              sh.export 'CODECLIMATE_REPO_TOKEN', config[:repo_token], echo: false
            end
          end
        end
      end
    end
  end
end

