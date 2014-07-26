require 'travis/shell/dsl'

module Travis
  module Build
    class Script
      module Helpers
        class AstProxy
          attr_reader :stack, :node

          def initialize(stack, node)
            @stack = stack
            @node = node
          end

          def method_missing(*args, &block)
            block = with_node(&block) if block
            node.send(*args, &block)
          end

          def with_node
            ->(node) {
              stack.push(AstProxy.new(stack, node))
              result = yield if block_given?
              stack.pop
              result
            }
          end
        end

        Shell::Dsl.instance_methods(false).each do |name|
          define_method(name) do |*args, &block|
            sh.send(name, *args, &block)
          end
        end

        def sh
          stack.last
        end

        def failure(message)
          echo message
          cmd 'false'
        end
      end
    end
  end
end
