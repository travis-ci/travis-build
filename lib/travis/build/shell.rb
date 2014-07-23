module Travis
  module Build
    module Shell
      autoload :Dsl,     'travis/build/shell/dsl'
      autoload :Filters, 'travis/build/shell/filters'
      autoload :Node,    'travis/build/shell/node'
      autoload :Cmd,     'travis/build/shell/node'
      autoload :Script,  'travis/build/shell/node'

      class InvalidParent < RuntimeError
        def initialize(node, required, actual)
          super("Node #{node.name} requires to be added to a #{required.name}, but is a #{actual.name}")
        end
      end
    end
  end
end
