module Travis
  module Build
    class Script
      module Addons
        class CodeClimate
          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def before_script
            if @config[:token]
              @script.set 'CODECLIMATE_REPO_TOKEN', @config[:token], echo: false, assert: false
            end
          end
        end
      end
    end
  end
end

