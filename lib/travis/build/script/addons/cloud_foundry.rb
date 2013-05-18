require 'travis/build/script/addons/deploy'

module Travis
  module Build
    class Script
      module Addons
        class CloudFoundry < Deploy
          def self.new(script, config)
            return super if self < CloudFoundry
            version  = config.to_hash[:version] if config.respond_to? :version
            subclass = version.to_i == 1 ? V1 : V2
            subclass.new(script, config)
          end

          class V1 < CloudFoundry
            private
              def tool_name
                "vmc"
              end
          end

          class V2 < CloudFoundry
            private
              def tool_name
                "cf"
              end
          end

          private
            def deploy
              cf "target #{option(:target)}"
              silent { cf "login --email #{option(:email)} --password #{option(:password)}" }
              cf "push #{app}"
            end

            def tools
              `gem install #{tool_name}`
            end

            def cf(cmd)
              `#{tool_name} #{cmd}`
            end
        end
      end
    end
  end
end
