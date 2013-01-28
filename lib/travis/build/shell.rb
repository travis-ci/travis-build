module Travis
  module Build
    module Shell
      autoload :Dsl,     'travis/build/shell/dsl'
      autoload :Windows, 'travis/build/shell/windows'
      #autoload :Filters, 'travis/build/shell/filters'
      autoload :Node,    'travis/build/shell/node'
      autoload :Cmd,     'travis/build/shell/node'

      Cmd.send(:include, Windows::Filters::Logging)
      Cmd.send(:include, Windows::Filters::Timeout)
      Cmd.send(:include, Windows::Filters::Assertion)
      Cmd.send(:include, Windows::Filters::Echoize)

      class InvalidParent < RuntimeError
        def initialize(node, parent)
          super("Node #{node.class.name} requires to be added to a node #{parent.class.name}")
        end
      end
    end
  end
end
