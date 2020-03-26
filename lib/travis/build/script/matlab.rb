module Travis
  module Build
    class Script
      class Matlab < Script
        MATLAB_INSTALLER_LOCATION = 'https://ssd.mathworks.com/supportfiles/ci/ephemeral-matlab/v0/install.sh'.freeze
        MATLAB_START = 'matlab -batch'.freeze
        MATLAB_COMMAND = "results = assertSuccess(runtests('IncludeSubfolders',true))".freeze

        DEFAULTS = {
          matlab: 'latest'
        }.freeze

        def export
          super
          sh.export 'TRAVIS_MATLAB_VERSION', config[:matlab].to_s.shellescape,
                    echo: false
        end

        def configure
          super
          # Invoke the ephemeral MATLAB installer that will make a MATLAB available
          # on the system PATH
          sh.raw "wget -qO- --retry-connrefused #{MATLAB_INSTALLER_LOCATION}" \
                 ' | sudo -E bash'
        end

        def script
          super
          # By default, invoke the default MATLAB 'runtests' command
          sh.cmd "#{MATLAB_START} \"#{MATLAB_COMMAND}\""
        end
      end
    end
  end
end
