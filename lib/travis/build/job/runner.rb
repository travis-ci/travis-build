module Travis
  module Build
    module Job
      class Runner
        autoload :Remote, 'travis/build/job/runner/remote'

        attr_reader :job, :observers

        def initialize(job)
          @job = job
          @observers = []
        end

        def name
          # TODO where to obtain the name?
          'ze monsta box'
        end

        def run
          notify :start, :started_at => Time.now
          result = perform
        rescue => e
          log_exception(e)
        ensure
          notify :finish, :finished_at => Time.now, :result => result
          result
        end

        protected

          def perform
            job.run
          end

          def log_exception(e)
            output = "Error: #{e.inspect}\n" + e.backtrace.map { |b| "  #{b}" }.join("\n")
            # puts output
            log(output)
          end

          def log(output)
            # could additionally collect the log on the job here if necessary
            notify :log, :output => output
          end

          def notify(type, data)
            observers.each { |observer| observer.notify(Event.new(type, job, data)) }
          end
      end
    end
  end
end
