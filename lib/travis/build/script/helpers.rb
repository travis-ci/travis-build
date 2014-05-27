module Travis
  module Build
    class Script
      module Helpers
        Shell::Dsl.instance_methods(false).each do |name|
          define_method(name) do |*args, &block|
            options = args.last if args.last.is_a?(Hash)
            sh.send(name, *args, &stacking(&block))
          end
        end

        def sh
          stack.last
        end

        def failure(message)
          echo message
          raw 'false'
        end

        def stacking
          ->(sh) {
            stack.push(sh)
            yield(sh) if block_given?
            stack.pop
          }
        end

        def announce?(stage)
          stage && stage != :after_result
        end
      end
    end
  end
end
