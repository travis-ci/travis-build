module Travis
  module Build
    module Shell
      autoload :Dsl,     'travis/build/shell/dsl'
      autoload :Filters, 'travis/build/shell/filters'
      autoload :Node,    'travis/build/shell/node'
      autoload :Cmd,     'travis/build/shell/node'

      Cmd.send(:include, Filters::Retry)
      Cmd.send(:include, Filters::Assertion)
      Cmd.send(:include, Filters::Echoize)

      class InvalidParent < RuntimeError
        def initialize(node, required, actual)
          super("Node #{node.name} requires to be added to a #{required.name}, but is a #{actual.name}")
        end
      end
    end
  end
end
