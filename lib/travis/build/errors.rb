module Travis
  module Build
    class CompilationError < StandardError
      attr_accessor :doc_path

      def initialize(msg = '')
        @msg = msg
      end

      def to_s
        @msg
      end
    end

    class EnvVarDefinitionError < CompilationError
      def initialize(msg = "Environment variables definition is incorrect.")
        super
      end

      def doc_path
        '/user/environment-variables'
      end
    end

    class DeployConfigError < CompilationError
      def initialize(msg = "The \\`deploy\\` configuration should be a map, or a sequence of maps.")
        super
      end

      def doc_path
        '/user/deployment'
      end
    end
  end
end
