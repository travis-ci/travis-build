module Travis
  module Build
    class Script
      module Addons
        class CodeClimate
          REQUIRES_SUPER_USER = false

          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            if @config[:repo_token]
              @script.set 'CODECLIMATE_REPO_TOKEN', @config[:repo_token], echo: false, assert: false
            end
          end
        end
      end
    end
  end
end

