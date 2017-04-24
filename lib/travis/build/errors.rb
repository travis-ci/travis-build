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
  end
end
