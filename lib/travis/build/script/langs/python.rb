module Travis
  module Build
    class Script
      class Python < Script
        DEFAULTS = {
          python: '2.7',
          virtualenv: { system_site_packages: false }
        }

        REQUIREMENTS_MISSING = 'Could not locate requirements.txt. Override the install: key in your .travis.yml to install dependencies.'
        SCRIPT_MISSING       = 'Please override the script: key in your .travis.yml to run tests.'

        def cache_slug
          super << "--python-" << config[:python].to_s
        end

        def export
          super
          sh.export 'TRAVIS_PYTHON_VERSION', config[:python]
        end

        def setup
          super
          sh.cmd "source #{virtualenv_activate}"
        end

        def announce
          sh.cmd 'python --version'
          sh.cmd 'pip --version'
        end

        def install
          sh.if '-f Requirements.txt' do
            sh.cmd 'pip install -r Requirements.txt', fold: 'install', retry: true
          end
          sh.elif '-f requirements.txt' do
            sh.cmd 'pip install -r requirements.txt', fold: 'install', retry: true
          end
          sh.else do
            sh.echo REQUIREMENTS_MISSING, ansi: :red
          end
        end

        def script
          # This always fails the build, asking the user to provide a custom :script.
          # The Python ecosystem has no good default build command most of the
          # community aggrees on. Per discussion with jezjez, josh-k and others. MK
          sh.terminate SCRIPT_MISSING
        end

        private

          def virtualenv_activate
            "~/virtualenv/#{python_version}#{system_site_packages}/bin/activate"
          end

          def python_version
            config[:python] =~ /pypy/i ? "pypy" : "python#{config[:python]}"
          end

          def system_site_packages
            if config[:virtualenv][:system_site_packages]
              "_with_system_site_packages"
            end
          end
      end
    end
  end
end

