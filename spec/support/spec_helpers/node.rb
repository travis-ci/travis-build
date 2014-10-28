module SpecHelpers
  module Node
    def create_node(type, *args)
      case type
      when :cmd, :file, :echo
        Travis::Shell::Ast::Cmd.new(type, *args)
      else
        const = type.to_s.sub(/^(.)/) { $1.upcase }
        Travis::Shell::Ast.const_get(const).new(*args)
      end
    end

    def add_elif(node, condition, cmds)
      branch = create_node(:elif, condition)
      node.branches << branch
      cmds.each { |cmd| branch.nodes << create_node(:cmd, cmd) }
      branch
    end

    def add_else(node, cmds)
      branch = create_node(:else)
      node.branches << branch
      cmds.each { |cmd| branch.nodes << create_node(:cmd, cmd) }
      branch
    end
  end
end

