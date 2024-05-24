require 'travis/build/stages/base'

module Travis
  module Build
    class Stages
      class Builtin < Base
        def run
          with_stage(name) do
            if name == :after_success || name == :after_failure
              puts "Builtin???: #{name}"
            end
            run_addon_stage :"before_#{name}"
            run_addon_stage :script if script? # TODO for coverity_scan
            if script.respond_to?(name, true)
              script.send(name)
              result if script?
            end
            run_addon_stage :"after_#{name}"
          end
        end
      end
    end
  end
end
