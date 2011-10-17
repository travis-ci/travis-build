module Travis
  class Build
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
