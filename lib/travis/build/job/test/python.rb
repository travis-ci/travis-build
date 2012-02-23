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
            if requirements_file_found?
              "pip install -r #{requirements_file_location}"
            else
              "echo 'Could not locate requirements.txt, not installing dependencies. Override install: key in your .travis.yml to install dependencies the way your project needs.'"
            end
          end

          def announce_versions
            shell.execute("python --version")
            shell.execute("pip --version")
          end

          def script
            # if we can do sane test tool detection by testing files or directories,
            # we should do it here. If not, Python projects will have to always override
            # script: key. MK.
            shell.execute ""
            fail_the_build("Please override script: key in your .travis.yml to run tests the way your project needs.")
          end

          protected

            def fail_the_build(msg)
              # no default for the Python builder, because Python ecosystem has
              # no good default most of the community agrees on. Per discussion with jezjez, josh-k
              # and several others.
              # This ALWAYS fails the build. MK.
              "echo '#{msg}' && /bin/false"
            end

            def export_environment_variables
              # export expected Python version in an environment variable as helper
              # for cross-version build in custom scripts
              shell.export_line("TRAVIS_PYTHON_VERSION=#{config.python}")
            end

            def requirements_file_location
              if shell.file_exists?("Requirements.txt")
                "Requirements.txt"
              else
                # heroku build pack uses this. MK.
                "requirements.txt"
              end
            end

            def requirements_file_found?
              shell.file_exists?("Requirements.txt") || shell.file_exists?("requirements.txt")
            end
        end
      end
    end
  end
end
