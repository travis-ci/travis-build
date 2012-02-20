require 'travis/support'
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
        build = configure? ? Build.new(events, job) : Build::Remote.new(vm, shell, events, job)
        observers.each { |observer| build.observers << observer }
        build
      end

      protected

        def job
          @job ||= if payload.type?
            self.send(payload.type)
          else
            # TODO this can be removed once this travis-core commit is deployed on travis-hub:
            # https://github.com/travis-ci/travis-core/commit/9157f820c0f7278a345cdd4a6967bf4d2751bd84
            configure? ? configure : test
          end
        end

        def events
          Event::Factory.new(payload)
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
