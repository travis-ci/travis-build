require 'hashr'

module Travis
  module Build
    class Factory
      attr_reader :config, :payload, :reporters

      def initialize(config, payload, reporters = [])
        @config = Hashr.new(config)
        @payload = Hashr.new(payload)
        @reporters = reporters
      end

      def instance
        payload.config? ? test : configure
      end

      def configure
        Job::Configure.new(http, commit)
      end

      def test
        Job::Test.new(shell, commit, payload.build.config).tap do |test|
          reporters.each do |reporter|
            test.observers << reporter
          end
        end
      end

      def http
        @http ||= Connection::Http.new(config)
      end

      def shell
        @shell ||= Shell.new(Shell::Session.new(config))
      end

      def commit
        @commit ||= Commit.new(repository, payload.build.commit)
      end

      def repository
        @repository ||= Repository::Github.new(scm, payload.repository.slug)
      end

      def scm
        @scm ||= Scm::Git.new(shell)
      end
    end
  end
end
