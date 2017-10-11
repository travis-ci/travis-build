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
          sh.cmd "source #{virtualenv_activate}"
        end

        def announce
          sh.cmd 'python --version'
          sh.cmd 'pip --version'
          sh.export 'PIP_DISABLE_PIP_VERSION_CHECK', '1', echo: false
        end

        def setup_cache
          if data.cache?(:pip)
            sh.fold 'cache.pip' do
              sh.echo ''
              directory_cache.add '$HOME/.cache/pip'
            end
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
            if version =~ /^pypy/
              if md = /^(?<interpreter>pypy[^-]*)(-(?<version>.*))?/.match(version)
                lang = md[:interpreter]
                vers = md[:version]
              end
            else
              lang = 'python'
              vers = version
            end
            sh.raw archive_url_for('travis-python-archives', vers, lang)
            sh.echo "Downloading archive: ${archive_url}", ansi: :yellow
            archive_basename = [lang, vers].compact.join("-")
            archive_filename = "#{archive_basename}.tar.bz2"
            sh.cmd "curl -s -o #{archive_filename} ${archive_url}", assert: true
            sh.cmd "sudo tar xjf #{archive_filename} --directory /", echo: true, assert: true
            sh.cmd "rm #{archive_filename}", echo: false
          end

          def setup_path(version = 'nightly')
            sh.cmd "echo 'export PATH=/opt/python/#{version}/bin:$PATH' | sudo tee -a #{PYENV_PATH_FILE} &>/dev/null"
          end
      end
    end
  end
end

