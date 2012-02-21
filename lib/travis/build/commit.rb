module Travis
  class Build

    # Models a commit hash on a repository so we do not have to pass both
    # around.
    class Commit
      attr_reader :repository, :hash

      def initialize(repository, hash)
        @repository = repository
        @hash = hash
      end

      def checkout
        repository.checkout(hash)
      end

      def config_url
        repository.config_url(hash)
      end
    end
  end
end
