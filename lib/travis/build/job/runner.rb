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

        def run
          notify(:start, job)
          result = perform
        rescue => e
          log_exception(job, e)
        ensure
          notify(:finish, job, :result => result)
          result
        end

        protected

          def perform
            job.run
          end

          def log_exception(job, e)
            output = "Error: #{e.inspect}\n" + e.backtrace.map { |b| "  #{b}" }.join("\n")
            # puts output
            log(job, output)
          end

          def log(job, output)
            # could additionally collect the log on the job here if necessary
            notify(:log, job, :output => output)
          end

          def notify(*args)
            observers.each { |observer| observer.notify(*args) }
          end
      end
    end
  end
end
