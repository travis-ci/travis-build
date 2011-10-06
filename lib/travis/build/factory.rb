require 'hashr'

module Travis
  module Build
    class Factory
      attr_reader :vm, :session, :config, :payload, :observers

      def initialize(vm, session, config, payload, observers = [])
        @vm = vm
        @session = session
        @config = Hashr.new(config)
        @payload = Hashr.new(payload)
        @observers = observers
      end

      def runner
        runner = configure? ? Job::Runner.new(job) : Job::Runner::Remote.new(vm, shell, job)
        observers.each { |observer| runner.observers << observer }
        runner
      end

      def job
        @job ||= configure? ? configure : test
      end

      def configure?
        !payload.config?
      end

      def configure
        @configure ||= Job::Configure.new(http, commit)
      end

      def test
        @test ||= begin
          type   = Job::Test.by_lang(payload.language)
          config = type::Config.new(payload.config)
          type.new(shell, commit, config)
        end
      end

      def http
        @http ||= Connection::Http.new(config)
      end

      def shell
        @shell ||= Shell.new(session)
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
