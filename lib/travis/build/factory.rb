require 'hashr'

module Travis
  class Build
    class Factory
      attr_reader :vm, :shell, :observers, :payload, :config

      def initialize(vm, shell, observers, payload, config)
        @vm = vm
        @shell = shell
        @observers = Array(observers)
        @payload = Hashr.new(payload)
        @config = Hashr.new(config)
      end

      def build
        build = configure? ? Build.new(job) : Build::Remote.new(vm, shell, job)
        observers.each { |observer| build.observers << observer }
        build
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

        def http
          @http ||= Connection::Http.new(config)
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
