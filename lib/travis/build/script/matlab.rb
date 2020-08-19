module Travis
  module Build
    class Script
      class Matlab < Script
        MATLAB_INSTALLER_LOCATION = 'https://ssd.mathworks.com/supportfiles/ci/ephemeral-matlab/v0/install.sh'.freeze
        MATLAB_DEPS_LOCATION = 'https://ssd.mathworks.com/supportfiles/ci/matlab-deps/v0/install.sh'.freeze
        MATLAB_START = 'matlab -batch'.freeze
        MATLAB_COMMAND = "assertSuccess(runtests('IncludeSubfolders',true));".freeze

        DEFAULTS = {
          matlab: 'latest'
        }.freeze

        def export
          super
          sh.export 'TRAVIS_MATLAB_VERSION', release.shellescape, echo: false
        end

        def setup
          super
          # Execute helper script to install runtime dependencies
          sh.raw "wget -qO- --retry-connrefused #{MATLAB_DEPS_LOCATION}" \
                 ' | sudo -E bash -s -- $TRAVIS_MATLAB_VERSION'

          # Invoke the ephemeral MATLAB installer that will make a MATLAB available
          # on the system PATH
          sh.raw "wget -qO- --retry-connrefused #{MATLAB_INSTALLER_LOCATION}" \
                 ' | sudo -E bash -s -- --release $TRAVIS_MATLAB_VERSION'
        end

        def script
          super
          # By default, invoke the default MATLAB 'runtests' command
          sh.cmd "#{MATLAB_START} \"#{MATLAB_COMMAND}\""
        end

        private
  
        def release
          Array(config[:matlab]).first.to_s
        end
      end
    end
  end
end
