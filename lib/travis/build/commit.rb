module Travis
  class Build

    # Models a commit hash on a repository so we do not have to pass both
    # around.
    class Commit
      attr_reader :repository, :build

      def initialize(repository, build)
        @repository = repository
        @build = build
      end

      def checkout
        repository.checkout(ref)
      end

      def ref
        build.commit
      end

      def config_url
        build.config_url
      end
    end
  end
end
