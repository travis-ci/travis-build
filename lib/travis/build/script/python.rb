module Travis
  module Build
    class Script
      class Python < Script
        DEFAULTS = {
          python: '2.7'
        }

        NO_REQUIREMENTS = 'Could not locate requirements.txt. Override the install: key in your .travis.yml to install dependencies.'
        NO_SCRIPT       = 'Please override the script: key in your .travis.yml to run tests.'

        def export
          super
          set 'TRAVIS_PYTHON_VERSION', config[:python]
        end

        def setup
          cmd "source #{virtualenv_activate}"
        end

        def announce
          cmd 'python --version'
          cmd 'pip --version'
        end

        def install
          sh_if   '-f Requirements.txt', "pip install -r Requirements.txt --use-mirrors"
          sh_elif '-f requirements.txt', "pip install -r requirements.txt --use-mirrors"
          sh_else { echo NO_REQUIREMENTS }
        end

        def script
          # This always fails the build, asking the user to provide a custom :script.
          # The Python ecosystem has no good default build command most of the
          # community aggrees on. Per discussion with jezjez, josh-k and others. MK
          failure NO_SCRIPT
        end

        private

          def virtualenv_activate
            if config[:python] =~ /pypy/i
              "~/virtualenv/pypy/bin/activate"
            else
              # python2.6, python2.7, python3.2, etc
              "~/virtualenv/python#{config[:python]}/bin/activate"
            end
          end
      end
    end
  end
end

