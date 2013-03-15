module Travis
  module Build
    class Script
      module Extras
        MAP = {}

        def run_extras
          extras.each do |extra|
            extra.run
          end
        end

        def extras
          @extras ||= (config[:extras] || {}).map do |name, extra_config|
            init_extra(name, extra_config)
          end
        end

        def init_extra(name, config)
          MAP[name].new(self, config)
        end
      end
    end
  end
end
