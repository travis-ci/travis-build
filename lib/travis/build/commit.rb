module Travis
  class Build

    # Models a commit hash on a repository so we do not have to pass both
    # around.
    class Commit
      attr_reader :repository, :job, :config, :scm

      def initialize(payload, scm)
        @repository = payload.repository
        @job        = payload.job || payload.build # TODO remove once payloads contain a :job key
        @scm        = scm
      end

      def checkout
        scm.fetch(repository.source_url, repository.slug, sha, ref)
      end

      def sha
        job.commit
      end

      def ref
        job.ref
      end

      def config_url
        job.config_url
      end
    end
  end
end
