module Travis
  module Build
    class Script
      class R < Script
        DEFAULTS = {
          # Basic config options
          cran: 'http://cran.rstudio.com',
          warnings_are_errors: false,
          # Dependencies (installed in this order)
          apt_packages: [],
          brew_packages: [],
          r_binary_packages: [],
          r_packages: [],
          bioc_packages: [],
          r_github_packages: [],
          # Build/test options
          r_build_args: '',
          r_check_args: '--as-cran',
          r_check_revdep: false,
          # Heavy dependencies
          pandoc: true,
          pandoc_version: '1.13.1',
          # Bioconductor
          bioc: 'http://bioconductor.org/biocLite.R',
          bioc_required: false,
          bioc_use_devel: false,
        }

        def initialize(data)
          # TODO(craigcitro): Is there a way to avoid explicitly
          # naming arguments here?
          super
          @devtools_installed = false
          @bioc_installed = false
        end

        def export
          super
          sh.export 'TRAVIS_R_VERSION', 'release', echo: false
        end

        def setup
          super

          # TODO(craigcitro): Confirm that these do, in fact, print as
          # green. (They're yellow under vagrant.)
          sh.echo 'R for Travis-CI is not officially supported, ' +
                  'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
                  ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues' +
                  '/new?labels=community:r', ansi: :green
          sh.echo 'and mention @craigcitro and @hadley in the issue',
                  ansi: :green

          # TODO(craigcitro): python-software-properties?
          sh.echo 'Installing R'
          case config[:os]
          when 'linux'
            # Set up our CRAN mirror.
            sh.cmd 'sudo add-apt-repository ' +
                   "\"deb #{config[:cran]}/bin/linux/ubuntu " +
                   "$(lsb_release -cs)/\""
            sh.cmd 'sudo apt-key adv --keyserver keyserver.ubuntu.com ' +
                   '--recv-keys E084DAB9'

            # Add marutter's c2d4u repository.
            sh.cmd 'sudo add-apt-repository -y "ppa:marutter/rrutter"'
            sh.cmd 'sudo add-apt-repository -y "ppa:marutter/c2d4u"'

            # Update after adding all repositories. Retry several
            # times to work around flaky connection to Launchpad PPAs.
            sh.cmd 'sudo apt-get update -qq', retry: true

            # Install an R development environment. qpdf is also needed for
            # --as-cran checks:
            #   https://stat.ethz.ch/pipermail/r-help//2012-September/335676.html
            sh.cmd 'sudo apt-get install -y --no-install-recommends r-base-dev ' +
                   'r-recommended qpdf', retry: true

            # Change permissions for /usr/local/lib/R/site-library
            # This should really be via 'sudo adduser travis staff'
            # but that may affect only the next shell
            sh.cmd 'sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library'

          when 'osx'
            # We want to update, but we don't need the 800+ lines of
            # output.
            sh.cmd 'brew update >/dev/null', retry: true

            # Install from latest CRAN binary build for OS X
            sh.cmd "wget #{config[:cran]}/bin/macosx/R-latest.pkg " +
                   '-O /tmp/R-latest.pkg'

            sh.echo 'Installing OS X binary package for R'
            sh.cmd 'sudo installer -pkg "/tmp/R-latest.pkg" -target /'
            sh.rm '/tmp/R-latest.pkg'

          else
            sh.failure "Operating system not supported: #{config[:os]}"
          end

          setup_latex
          
          setup_bioc if needs_bioc?
          setup_pandoc if config[:pandoc]
        end

        def announce
          super

          sh.cmd 'Rscript -e \'sessionInfo()\''
          sh.echo ''
        end

        def install
          super

          # Install any declared packages
          apt_install config[:apt_packages]
          brew_install config[:brew_packages]
          r_binary_install config[:r_binary_packages]
          r_install config[:r_packages]
          bioc_install config[:bioc_packages]
          r_github_install config[:r_github_packages]

          # Install dependencies for the package we're testing.
          install_deps
        end

        def script
          # Build the package
          sh.echo "Building with: R CMD build ${R_BUILD_ARGS}"
          sh.cmd "R CMD build #{config[:r_build_args]} .",
                 assert: true
          tarball_script = [
            'pkg <- devtools::as.package(".");',
            'cat(paste0(pkg$package, "_", pkg$version, ".tar.gz"));',
          ].join(' ')
          sh.export 'PKG_TARBALL', "$(Rscript -e '#{tarball_script}')"

          # Test the package
          sh.echo 'Testing with: R CMD check "${PKG_TARBALL}" ' +
                  "#{config[:r_check_args]}"
          sh.cmd "R CMD check \"${PKG_TARBALL}\" #{config[:r_check_args]}",
                 assert: false
          # Build fails if R CMD check fails
          sh.if '$? -ne 0' do
            sh.echo 'R CMD check failed, dumping logs'
            dump_logs
            sh.failure 'R CMD check failed'
          end

          # Turn warnings into errors, if requested.
          if config[:warnings_are_errors]
            export_rcheck_dir
            sh.cmd 'grep -q -R "WARNING" "${RCHECK_DIR}/00check.log"; ' +
                   'RETVAL=$?'
            sh.if '${RETVAL} -eq 0' do
              sh.failure "Found warnings, treating as errors (as requested)."
            end
          end
          
          # Check revdeps, if requested.
          if config[:r_check_revdep]
            sh.echo "Checking reverse dependencies"
            revdep_script = [
              'library("devtools");',
              'res <- revdep_check();',
              'if (length(res) > 0) {',
              ' revdep_check_summary(res);',
              ' revdep_check_save_logs(res);',
              ' q(status = 1, save = "no");',
              '}',
            ].join(' ')
            sh.cmd "Rscript -e '#{revdep_script}'", assert: true
          end

        end

        private

        def needs_bioc?
          config[:bioc_required] || !config[:bioc_packages].empty?
        end

        def packages_as_arg(packages)
          quoted_pkgs = packages.collect{|p| "\"#{p}\""}
          "c(#{quoted_pkgs.join(', ')})"
        end

        def as_r_boolean(bool)
          bool ? "TRUE" : "FALSE"
        end

        def r_install(packages)
          return if packages.empty?
          sh.echo "Installing R packages: #{packages.join(', ')}"
          pkg_arg = packages_as_arg(packages)
          install_script = [
            "install.packages(#{pkg_arg}, repos=\"#{config[:cran]}\");",
            "if (!all(#{pkg_arg} %in% installed.packages())) {",
            ' q(status = 1, save = "no")',
            '}',
          ].join(' ')
          sh.cmd "Rscript -e '#{install_script}'"
        end

        def r_github_install(packages)
          return if packages.empty?
          setup_devtools
          sh.echo "Installing R packages from github: #{packages.join(', ')}"
          pkg_arg = packages_as_arg(packages)
          install_script = [
            "options(repos = c(CRAN = \"#{config[:cran]}\"));",
            'tryCatch({',
            "  devtools::install_github(#{pkg_arg}, build_vignettes = FALSE)",
            '}, error = function(e) {',
            '  message(e);',
            '  q(status = 1, save = "no")',
            '})',
          ].join(' ')
          sh.cmd "Rscript -e '#{install_script}'"
        end
        
        def r_binary_install(packages)
          return if packages.empty?
          case config[:os]
          when 'linux'
            sh.echo "Installing *binary* R packages: #{packages.join(', ')}"
            apt_install packages.collect{|p| "r-cran-#{p.downcase}"}
          else
            sh.echo "R binary packages not supported on #{config[:os]}, " +
                    'falling back to source install'
            r_install packages
          end
        end

        def apt_install(packages)
          return if packages.empty?
          return unless (config[:os] == 'linux')
          pkg_arg = packages.join(' ')
          sh.echo "Installing apt packages: #{packages.join(', ')}"
          sh.cmd "sudo apt-get install -y #{pkg_arg}", retry: true
        end

        def brew_install(packages)
          return if packages.empty?
          return unless (config[:os] == 'osx')
          pkg_arg = packages.join(' ')
          sh.echo "Installing brew packages: #{packages.join(', ')}"
          sh.cmd "brew install #{pkg_arg}", retry: true
        end

        def bioc_install(packages)
          return if packages.empty?
          return unless needs_bioc?
          setup_bioc
          sh.echo "Installing bioc packages: #{packages.join(', ')}"
          pkg_arg = packages_as_arg(packages)
          install_script = [
            "source(\"#{config[:bioc]}\");",
            'options(repos=biocinstallRepos());',
            "biocLite(#{pkg_arg});",
            "if (!all(#{pkg_arg} %in% installed.packages())) {",
            ' q(status = 1, save = "no")',
            '}',
          ].join(' ')
          sh.cmd "Rscript -e '#{install_script}'"
        end

        def install_deps
          setup_devtools
          if not needs_bioc?
            repos = "\"#{config[:cran]}\""
          else
            repos = 'BiocInstaller::biocinstallRepos()'
          end
          install_script = [
            "options(repos = #{repos});",
            'tryCatch({',
            '  deps <- devtools::install_deps(dependencies = TRUE)',
            '}, error = function(e) {',
            '  message(e);',
            '  q(status=1)',
            '});',
            'if (!all(deps %in% installed.packages())) {',
            ' message("missing: ", paste(setdiff(deps, installed.packages()), collapse=", "));',
            ' q(status = 1, save = "no")',
            '}',
          ].join(' ')
          sh.cmd "Rscript -e '#{install_script}'"
        end

        def export_rcheck_dir
          pkg_script = (
            'cat(paste0(devtools::as.package(".")$package, ".Rcheck"))'
          )
          sh.export 'RCHECK_DIR', "$(Rscript -e '#{pkg_script}')"
        end
        
        def dump_logs
          export_rcheck_dir
          ['out', 'log', 'fail'].each do |ext|
            cmd = [
              'for name in',
              "$(find \"${RCHECK_DIR}\" -type f -name \"*#{ext}\");",
              'do',
              'echo ">>> Filename: ${name} <<<";',
              'cat ${name};',
              'done',
            ].join(' ')
            sh.cmd cmd
          end
        end
        
        def setup_bioc
          unless @bioc_installed
            sh.echo 'Installing BioConductor'
            bioc_install_script = [
              "source(\"#{config[:bioc]}\");",
              'tryCatch(',
              " useDevel(#{as_r_boolean(config[:bioc_use_devel])}),",
              ' error=function(e) {if (!grepl("already in use", e$message)) {e}}',
              ');',
            ].join(' ')
            sh.cmd "Rscript -e '#{bioc_install_script}'", retry: true
          end
          @bioc_installed = true
        end

        def setup_devtools
          unless @devtools_installed
            case config[:os]
            when 'linux'
              r_binary_install ['devtools']
            else
              devtools_check = '!requireNamespace("devtools", quietly = TRUE)'
              devtools_install = 'install.packages(c("devtools"), ' +
                                 "repos=\"#{config[:cran]}\")"
              sh.cmd "Rscript -e 'if (#{devtools_check}) #{devtools_install}'",
                     retry: true
            end
          end
          @devtools_installed = true
        end

        def setup_latex
          case config[:os]
          when 'linux'
            # We add a backports PPA for more recent TeX packages.
            sh.cmd 'sudo add-apt-repository -y "ppa:texlive-backports/ppa"'

            latex_packages = %w[
                   lmodern texinfo texlive-base texlive-extra-utils
                   texlive-fonts-extra texlive-fonts-recommended
                   texlive-generic-recommended texlive-latex-base
                   texlive-latex-extra texlive-latex-recommended
            ]
            sh.cmd 'sudo apt-get install -y --no-install-recommends ' +
                   "#{latex_packages.join(' ')}",
                   retry: true
          when 'osx'
            # We use basictex due to disk space constraints.
            mactex = 'BasicTeX.pkg'
            # TODO(craigcitro): Confirm that this will route us to the
            # nearest mirror.
            sh.cmd 'wget http://mirror.ctan.org/systems/mac/mactex/' +
                   "#{mactex} -O \"/tmp/#{mactex}\""

            sh.echo 'Installing OS X binary package for MacTeX'
            sh.cmd "sudo installer -pkg \"/tmp/#{mactex}\" -target /"
            sh.rm "/tmp/#{mactex}"
            sh.cmd 'sudo /usr/texbin/tlmgr update --self'
            sh.cmd 'sudo /usr/texbin/tlmgr install inconsolata upquote ' +
                   'courier courier-scaled helvetic'

            sh.export 'PATH', '$PATH:/usr/texbin'
          end
        end

        def setup_pandoc
          case config[:os]
          when 'linux'
            os_path = 'linux/debian/x86_64'
          when 'osx'
            os_path = 'mac'
          end

          pandoc_url = 'https://s3.amazonaws.com/rstudio-buildtools/pandoc-' +
                       "#{config[:pandoc_version]}.zip"
          pandoc_srcdir = "pandoc-#{config[:pandoc_version]}/#{os_path}"
          pandoc_destdir = '${HOME}/opt/pandoc'
          pandoc_tmpfile = "/tmp/pandoc-#{config[:pandoc_version]}.zip"
          
          sh.mkdir pandoc_destdir, recursive: true
          sh.cmd "curl -o #{pandoc_tmpfile} #{pandoc_url}"
          ['pandoc', 'pandoc-citeproc'].each do |filename|
            binary_srcpath = File.join(pandoc_srcdir, filename)
            sh.cmd "unzip -j #{pandoc_tmpfile} #{binary_srcpath} " +
                   "-d #{pandoc_destdir}"
            sh.chmod '+x', "#{File.join(pandoc_destdir, filename)}"
          end
          
          sh.export 'PATH', "$PATH:#{pandoc_destdir}"
        end
        
      end
    end
  end
end
