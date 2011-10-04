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
        end

        protected

          def perform
            job.run
          end

          def log(job, output)
            # could additionally collect the log on the job here
            notify(:log, job, :output => output)
          end

          def log_exception(job, e)
            log(job, "Error: #{e.inspect}" + e.backtrace.map { |b| "  #{b}" }.join("\n"))
          end

          def notify(event, *args)
            observers.each do |observer|
              observer.send(:"on_#{event}", *args) if observer.respond_to?(:"on_#{event}")
            end
          end
      end
    end
  end
end
