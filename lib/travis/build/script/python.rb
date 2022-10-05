module Travis
  module Build
    class Script
      class Python < Script
        DEFAULTS = {
          python: '3.6',
          virtualenv: { system_site_packages: false }
        }

        DEPRECATIONS = [
          {
            name: 'Python',
            current_default: DEFAULTS[:python],
            new_default: '3.6',
            cutoff_date: '2019-04-16',
          }
        ]

        PIP_20_3_MSG = [
          "Pip version 20.3 introduces changes to the dependency resolver that may affect your software.",
          "We advise you to consider testing the upcoming changes, which may be introduced in a future Travis CI build image update.",
          "See https://pip.pypa.io/en/latest/user_guide/#changes-to-the-pip-dependency-resolver-in-20-2-2020 for more information."
        ]
        PIP_20_2_MSG = "With pip 20.2, you can test the new dependency resolver with the \\\`--use-feature=2020-resolver\\\` flag."

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
          sh.export 'PIP_PROGRESS_BAR', 'off', echo: false
        end

        def setup_cache
          if data.cache?(:pip)
            sh.fold 'cache.pip' do
              sh.newline
              directory_cache.add '${TRAVIS_HOME}/.cache/pip'
            end
          end
        end

        def install
          warn_pip_20_3
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
          # community agrees on. Per discussion with jezjez, josh-k and others. MK
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
            Array(config[:python]).first.to_s
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
            sh.cmd "curl -sSf --retry 5 -o #{archive_filename} ${archive_url}", echo: true, assert: false, timing: true
            sh.if "$? != 0" do
              sh.failure "Unable to download #{version} archive. The archive may not exist. Please consider a different version."
            end
            sh.cmd "sudo #{tar_extract} #{archive_filename} --directory /", echo: true, assert: true, timing: true
            sh.cmd "rm #{archive_filename}", echo: false
          end

          def tar_extract
            case config[:os]
            when 'freebsd'
              "tar xPjf"
            else
              "tar xjf"
            end
          end

          def setup_path(version = 'nightly')
            sh.cmd "echo 'export PATH=/opt/python/#{version}/bin:$PATH' | sudo tee -a #{PYENV_PATH_FILE} &>/dev/null"
          end

          def pip_version_at_least_20_2?
            "$(travis_vers2int $(pip --version | cut -f2 -d \" \")) -ge $(travis_vers2int \"20.2\")"
          end
          def pip_version_before_20_3?
            "$(travis_vers2int $(pip --version | cut -f2 -d \" \")) -lt $(travis_vers2int \"20.3\")"
          end

          def warn_pip_20_3
            sh.if pip_version_before_20_3? do
              PIP_20_3_MSG.each { |l| sh.echo l, ansi: :yellow }

              sh.if pip_version_at_least_20_2? do
                sh.echo PIP_20_2_MSG, ansi: :yellow
              end

              sh.echo
            end
          end
      end
    end
  end
end
