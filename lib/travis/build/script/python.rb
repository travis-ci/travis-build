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

        PYENV_PATH_FILE      = '/etc/profile.d/pyenv.sh'
        TEMP_PYENV_PATH_FILE = '/tmp/pyenv.sh'

        def export
          super
          sh.export 'TRAVIS_PYTHON_VERSION', version, echo: false
        end

        def configure
          super
          sh.if "! -f #{virtualenv_activate}" do
            sh.echo "#{version} is not installed; attempting download", ansi: :yellow
            install_python_archive version
            setup_path version
          end
        end

        def setup
          super
          setup_cache
          sh.cmd "source #{virtualenv_activate}"
        end

        def announce
          sh.cmd 'python --version'
          sh.cmd 'pip --version'
        end

        def setup_cache
          if data.cache?(:pip)
            directory_cache.add '$HOME/.cache/pip'
          end
        end

        def install
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

          def install_python_archive(version = 'nightly')
            sh.cmd "curl -s -o python-#{version}.tar.bz2 https://s3.amazonaws.com/travis-python-archives/$(lsb_release -rs)/python-#{version}.tar.bz2", echo: false
            sh.cmd "sudo tar xjf python-#{version}.tar.bz2 --directory /", echo: false
            sh.cmd "rm python-#{version}.tar.bz2", echo: false
          end

          def setup_path(version = 'nightly')
            sh.cmd "sed -e 's|export PATH=\\(.*\\)$|export PATH=/opt/python/#{version}/bin:\\1|' #{PYENV_PATH_FILE} > #{TEMP_PYENV_PATH_FILE}"
            sh.cmd "cat #{TEMP_PYENV_PATH_FILE} | sudo tee #{PYENV_PATH_FILE} > /dev/null"
          end
      end
    end
  end
end

