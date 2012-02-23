module Travis
  class Build
    module Job
      class Test
        class Python < Test
          class Config < Hashr
          end

          def setup
            super
            shell.execute "source #{virtualenv_activate_location}"
            announce_versions
          end

          def virtualenv_activate_location
            # python2.6, python2.7, python3.2, etc
            "~/virtualenv/python#{config.python}/bin/activate"
          end

          def install
          end

          def announce_versions
            shell.execute("python --version")
            shell.execute("pip --version")
          end

          def script
          end

          protected

            def run_default
              "make test"
            end

            def export_environment_variables
              # export expected Python version in an environment variable as helper
              # for cross-version build in custom scripts
              shell.export_line("TRAVIS_PYTHON_VERSION=#{config.python}")
            end
        end
      end
    end
  end
end
