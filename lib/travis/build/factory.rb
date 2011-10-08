require 'hashr'

module Travis
  module Build
    class Factory
      attr_reader :vm, :session, :http, :payload, :observers

      def initialize(vm, session, http, payload, observers = [])
        @vm = vm
        @session = session
        @http = http
        @payload = Hashr.new(payload)
        @observers = Array(observers)
      end

      def runner
        runner = configure? ? Job::Runner.new(job) : Job::Runner::Remote.new(vm, shell, job)
        observers.each { |observer| runner.observers << observer }
        runner
      end

      protected

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
            type   = Job::Test.by_lang(payload.config.language)
            config = type::Config.new(payload.config)
            type.new(shell, commit, config)
          end
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
