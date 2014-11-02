module Travis
  module Build
    class Script
      class Stages
        class Builtin < Base
          def run
            with_stage(name) do
              run_addon_stage :"before_#{name}"
              script.send(name)
              result if script?
              run_addon_stage :"after_#{name}"
            end
          end

          def run_addon_stage(name)
            Addon.new(script, name).run
          end
        end
      end
    end
  end
end
