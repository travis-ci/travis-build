module Travis
  class Build

    # Models a commit hash on a repository so we do not have to pass both
    # around.
    class Commit
      attr_reader :repository, :job, :config, :scm, :build

      def initialize(payload, scm)
        @repository = payload.repository
        @job        = payload.job
        @build      = payload.build
        @scm        = scm
      end

      def checkout
        scm.fetch(repository.source_url, repository.slug, sha, branch, ref)
      end

      def sha
        job.commit
      end

      def ref
        job.ref
      end
      
      def branch
        job.branch
      end

      def config_url
        job.config_url
      end

      def pull_request
        job.pull_request
      end

      def pull_request?
        !!pull_request
      end

      def job_id
        job.id
      end
    end
  end
end
