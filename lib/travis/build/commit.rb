module Travis
  class Build

    # Models a commit hash on a repository so we do not have to pass both
    # around.
    class Commit
      attr_reader :repository, :build, :config, :scm

      def initialize(payload, scm)
        @repository = payload.repository
        @build      = payload.build
        @config     = payload.config
        @scm        = scm
      end

      def checkout
        scm.fetch(repository.source_url, ref, repository.slug, config)
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
