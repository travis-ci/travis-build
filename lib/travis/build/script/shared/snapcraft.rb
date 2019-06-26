module Travis
  module Build
    class Script
      module Snapcraft

        def script
          cmds = Array(config[name])
          cmds.each_with_index do |command, ix|
            sh.cmd command.to_s, echo: true, fold: fold_for(name, cmds, ix)
            result if script?
          end
        end

        private

        def fold_for(part, cmds, ix)
          "#{part}#{".#{ix + 1}" if cmds.size > 1}" if fold_part?(part)
        end

        def fold_part(part)
          valid_parts  = ['Pulling', 'Building', 'Staging', 'Priming', 'Snapping']
          if valid_parts.any? { |valid_part| part.include? (valid_part) }
            part = part.split(" ")
            return part[1].match(/^[a-z0-9-]*$/) if part[1]
          end
          return false
        end
      end
    end
  end
end
