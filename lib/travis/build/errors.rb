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
      def initialize(msg = "The \\`deploy\\` configuration should be a hash (dictionary), or an array of hashes.")
        super
      end

      def doc_path
        '/user/deployment'
      end
    end

    class DeployConditionError < DeployConfigError
      def initialize(msg = "\\`deploy.on\\` should be a hash (dictionary).")
        super
      end

      def doc_path
        '/user/deployment#Conditional-Releases-with-on%3A'
      end
    end

    class AptSourcesConfigError < CompilationError
      def initialize(msg = "\\`apt\\` should be a hash with key \\`sources\\` and an array as a value.")
        super
      end

      def doc_path
        '/user/installing-dependencies'
      end
    end

    class AptPackagesConfigError < CompilationError
      def initialize(msg = "\\`apt\\` should be a hash with key \\`packages\\` and an array as a value.")
        super
      end

      def doc_path
        '/user/installing-dependencies'
      end
    end

    class SnapsConfigError < CompilationError
      def initialize(msg = "\\`snaps\\` should be a list.")
        super
      end

      def doc_path
        '/user/installing-dependencies'
      end
    end
  end
end
