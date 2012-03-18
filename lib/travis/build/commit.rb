module Travis
  class Build

    # Models a commit hash on a repository so we do not have to pass both
    # around.
    class Commit
      attr_reader :repository, :build, :scm

      def initialize(build, repository, scm)
        @repository = repository
        @build = build
        @scm = scm
      end

      def checkout
        scm.fetch(repository.source_url, ref, repository.slug)
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
