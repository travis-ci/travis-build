require 'travis/shell/ast'
require 'travis/shell/builder'
require 'travis/shell/generator'
require 'travis/shell/generator/bash'

module Travis
  module Shell
    class << self
      def generate(nodes)
        Generator::Bash.new(nodes).generate
      end
    end
  end
end
