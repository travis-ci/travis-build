require 'travis'

module Travis
  module Build
    module Services
      class BuildScript < Travis::Services::Base
        register :build_script

        def run
          Travis::Build.script(data.merge(urls: urls)).compile
          # Travis::Build.script(data).compile
        end

        private

          def urls
            # TODO where to put this configuration?
            {
              log:   "http://192.168.2.100:3000/jobs/#{params[:id]}/log",
              state: "http://192.168.2.100:3000/jobs/#{params[:id]}/state"
            }
          end

          def data
            Travis::Api.data(job, for: 'worker', type: 'Job::Test', version: 'v0')
          end

          def job
            run_service(:find_job, id: params[:id])
          end
      end
    end
  end
end
