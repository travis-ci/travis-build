require 'travis/support'

module Travis
  # Encapsulates a build that is run on a worker. Build is both used for
  # running a Job::Configure as well as a base class for Build::Remote which
  # runs a Job::Test in a VM.
  #
  # Implements a simple observer pattern to notify observers about state
  # changes and stream log output.
  #
  # A Build takes an event factory which knows how to create events and a
  # job.
  #
  # TODO passing the event factory seems quite odd, doesn't it? Maybe we
  # could just have a Context which is notified?
  class Build
    # not quite sure where to best put this
    class OutputLimitExceeded < RuntimeError
      def intitialize(limit)
        super("The log length has exceeded the limit of #{limit} Bytes (this usually means that test suite is raising the same exception over and over). Terminating.")
      end
    end

    autoload :Connection, 'travis/build/connection'
    autoload :Commit,     'travis/build/commit'
    autoload :Event,      'travis/build/event'
    autoload :Factory,    'travis/build/factory'
    autoload :Job,        'travis/build/job'
    autoload :Remote,     'travis/build/remote'

    module Repository
      autoload :Github, 'travis/build/repository/github'
    end

    module Scm
      autoload :Git, 'travis/build/scm/git'
    end

    include Logging

    log_header { "#{Thread.current[:log_header]}:build" }

    def self.create(*args)
      Factory.new(*args).build
    end

    attr_reader :events, :job, :observers

    def initialize(events, job)
      @job = job
      @events = events
      @observers = []
    end

    def run
      notify :start, :started_at => Time.now.utc
      result = perform
    rescue => e
      log_exception(e)
      result = {}
    ensure
      notify :finish, (result || {}).merge(:finished_at => Time.now.utc)
      result
    end
    log :run

    protected

      def perform
        job.run
      end

      def log_exception(e)
        log "Error: #{e.inspect}\n" + e.backtrace.map { |b| "  #{b}" }.join("\n")
      end

      def log(output, options = {})
        # could additionally collect the log on the job here if necessary
        notify :log, :log => output

        # TODO should log the output here. in order to do this the build needs to have
        # a log_header that includes the current worker name though
        info output, options
      end

      def notify(type, data)
        event = events.create(type, job, data)
        observers.each { |observer| observer.notify(event.name, event.data) }
      end
  end
end
