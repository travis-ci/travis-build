module Travis
  class Build

    # Models a commit hash on a repository so we do not have to pass both
    # around.
    class Commit
      attr_reader :repository, :build, :config, :scm

      def initialize(payload, scm)
        @repository = payload.repository
        @build      = payload.build
        @scm        = scm
      end

      def checkout
        scm.fetch(repository.source_url, repository.slug, sha, ref)
      end

      def sha
        build.commit
      end

      def ref
        build.ref
      end

      def config_url
        build.config_url
      end

      def branch
        repository.ref.gsub( "refs/heads/", "" )
      end
    end
  end
end
