require 'travis/support'
require 'hashr'

module Travis
  class Build

    # Constructs a Build and should not be used directly. Will be instantiated
    # and used in `Travis::Build.create` which is intended to be the public API.
    #
    # The factory knows about basically all the classes used in Travis::Build
    # and will wire them up for us and pass them down to constructors. I.e. it
    # centralizes all knowledge about dependencies. This pattern of "having a
    # central fat factory" at "boundaries" within our domain model is used in
    # both travis-worker and travis-build and makes it easy to pass down mock
    # objects in tests instead of real dependencies.
    #
    # In other words the constraint is to not use class names (i.e. instantiate
    # objects within domain models). On the other hand we don't want to use a
    # DI mechanism either.
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
          @job ||= self.send(payload['type'])
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
