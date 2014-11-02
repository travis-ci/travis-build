module Travis
  module Build
    class Script
      class Stages
        class Custom < Base
          def run
            with_stage(name) do
              cmds = Array(config[name])
              cmds.each_with_index do |command, ix|
                sh.cmd command, echo: true, fold: fold_for(name, cmds, ix)
                result if script?
              end
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
end
