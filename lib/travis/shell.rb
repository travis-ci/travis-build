require 'travis/shell/ast'
require 'travis/shell/builder'
require 'travis/shell/generator'
require 'travis/shell/generator/bash'

module Travis
  module Shell
    class << self
      def generate(nodes, ignore_taint = false)
        Generator::Bash.new(nodes).generate(ignore_taint)
      end
    end
  end
end
