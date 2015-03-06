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

        DEV_VERSIONS = %w( 3.5 3.5-dev )

        def export
          super
          sh.export 'TRAVIS_PYTHON_VERSION', version, echo: false
        end

        def setup
          super
          if DEV_VERSIONS.include? version
            install_python_dev
          end
          sh.cmd "source #{virtualenv_activate}"
        end

        def announce
          sh.cmd 'python --version'
          sh.cmd 'pip --version'
        end

        def install
          if data.cache?(:pip)
            directory_cache.add '$HOME/.cache/pip'
          end
          sh.if '-f Requirements.txt' do
            sh.cmd 'pip install -r Requirements.txt', fold: 'install', retry: true
          end
          sh.elif '-f requirements.txt' do
            sh.cmd 'pip install -r requirements.txt', fold: 'install', retry: true
          end
          sh.else do
            sh.echo REQUIREMENTS_MISSING # , ansi: :red
          end
        end

        def script
          # This always fails the build, asking the user to provide a custom :script.
          # The Python ecosystem has no good default build command most of the
          # community aggrees on. Per discussion with jezjez, josh-k and others. MK
          sh.failure SCRIPT_MISSING
        end

        def cache_slug
          super << '--python-' << version
        end

        def use_directory_cache?
          super || data.cache?(:pip)
        end

        private

          def version
            config[:python].to_s
          end

          def virtualenv_activate
            "~/virtualenv/#{virtualenv}#{system_site_packages}/bin/activate"
          end

          def virtualenv
            pypy? ? version : "python#{version}"
          end

          def pypy?
            config[:python] =~ /pypy/i
          end

          def system_site_packages
            '_with_system_site_packages' if config[:virtualenv][:system_site_packages]
          end

          def install_python_dev
            sh.cmd 'curl -s -o python-3.5-dev.tar.bz2 https://s3.amazonaws.com/travis-python-archives/python-3.5-dev.tar.bz2', echo: false
            sh.cmd 'sudo tar xjf python-3.5-dev.tar.bz2 --directory /', echo: false
            sh.cmd 'rm python-3.5-dev.tar.bz2', echo: false
          end
      end
    end
  end
end

