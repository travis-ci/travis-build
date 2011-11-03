module Travis
  class Build
    autoload :Assertions, 'travis/build/assertions'
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
      notify :start, :started_at => Time.now
      result = perform
    rescue => e
      log_exception(e)
      result = {}
    ensure
      notify :finish, result.merge(:finished_at => Time.now)
      result
    end

    protected

      def perform
        job.run
      end

      def log_exception(e)
        log("Error: #{e.inspect}\n" + e.backtrace.map { |b| "  #{b}" }.join("\n"))
      end

      def log(output)
        # could additionally collect the log on the job here if necessary
        notify :log, :log => output
      end

      def notify(type, data)
        event = events.create(type, job, data)
        observers.each { |observer| observer.notify(event) }
      end
  end
end
