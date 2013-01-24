require 'travis'

module Travis
  module Build
    module Services
      class BuildScript < Travis::Services::Base
        register :build_script

        def run
          job ? Travis::Build.script(data).compile : not_found
        end

        private

          def data
            Travis::Api.data(job, for: 'worker', type: 'Job::Test', version: 'v0')
          end

          def job
            @job ||= run_service(:find_job, id: params[:id])
          end

          def not_found
            "echo \"The build.sh for the job #{params[:id].inspect} could not be generated: job not found.\"; exit 2"
          end
      end
    end
  end
end
