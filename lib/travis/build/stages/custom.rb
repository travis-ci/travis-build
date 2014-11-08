require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Custom < Base
        def run
          with_stage(name) do
            run_addon_stage :"before_#{name}"
            run_addon_stage :script if script? # TODO for coverity_scan
            cmds = Array(config[name])
            cmds.each_with_index do |command, ix|
              sh.cmd command.to_s, echo: true, fold: fold_for(name, cmds, ix)
              result if script?
            end
            run_addon_stage :"after_#{name}"
          end
        end

        private

          def fold_for(stage, cmds, ix)
            "#{stage}#{".#{ix + 1}" if cmds.size > 1}" if fold_stage?(stage)
          end

          def fold_stage?(stage)
            stage != :script
          end
      end
    end
  end
end
