# Maintained by:
# Jim Hester     @jimhester       james.hester@rstudio.com
# Craig Citro    @craigcitro      craigcitro@google.com
# Hadley Wickham @hadley          hadley@rstudio.com
#
module Travis
  module Build
    class Script
      class R < Script
        DEFAULTS = {
          # Basic config options
          cran: 'https://cloud.r-project.org',
          repos: {},
          warnings_are_errors: true,
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
          pandoc_version: '1.15.2',
          # Bioconductor
          bioc: 'https://bioconductor.org/biocLite.R',
          bioc_required: false,
          bioc_use_devel: false,
          r: 'release'
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
          sh.export 'TRAVIS_R_VERSION', r_version, echo: false
          sh.export 'R_LIBS_USER', '~/R/Library', echo: false
          sh.export 'R_LIBS_SITE', '/usr/local/lib/R/site-library:/usr/lib/R/site-library'
          sh.export '_R_CHECK_CRAN_INCOMING_', 'false', echo: false
          sh.export 'NOT_CRAN', 'true', echo: false
          sh.export 'R_PROFILE', "~/.Rprofile.site", echo: false
        end

        def configure
          super

          sh.echo 'R for Travis-CI is not officially supported, '\
                  'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues at https://github.com/travis-ci/travis-ci/issues'
          sh.echo 'and mention @craigcitro, @hadley and @jimhester in the issue'

          sh.fold 'R-install' do
            sh.with_options({ assert: true,  echo: true,  timing: true  }) do
              sh.echo 'Installing R', ansi: :yellow
              case config[:os]
              when 'linux'
                # Set up our CRAN mirror.
                sh.cmd 'sudo add-apt-repository '\
                  "\"deb #{repos[:CRAN]}/bin/linux/ubuntu "\
                  "$(lsb_release -cs)/\""
                sh.cmd 'sudo apt-key adv --keyserver keyserver.ubuntu.com '\
                  '--recv-keys E084DAB9'

                # Add marutter's c2d4u repository.
                sh.cmd 'sudo add-apt-repository -y "ppa:marutter/rrutter"'
                sh.cmd 'sudo add-apt-repository -y "ppa:marutter/c2d4u"'

                # Update after adding all repositories. Retry several
                # times to work around flaky connection to Launchpad PPAs.
                sh.cmd 'sudo apt-get update -qq', retry: true

                # Install precompiled R if on precise
                sh.if '$(lsb_release -cs) == "precise"' do
                  # Install only the dependencies for an R development environment except for
                  # libpcre3-dev or r-base-core because they will be included in
                  # the R binary tarball.
                  # Dependencies queried with `apt-cache depends -i r-base-dev`.
                  # qpdf and texinfo are also needed for --as-cran # checks:
                  # https://stat.ethz.ch/pipermail/r-help//2012-September/335676.html
                  sh.cmd 'sudo apt-get install -y --no-install-recommends '\
                    'build-essential gcc g++ gfortran libblas-dev liblapack-dev '\
                    'libncurses5-dev libreadline-dev libjpeg-dev '\
                    'libpng-dev zlib1g-dev libbz2-dev liblzma-dev cdbs qpdf texinfo', retry: true

                  r_filename = "R-#{r_version}.xz"
                  r_url = "https://s3.amazonaws.com/rstudio-travis/R-#{r_version}.xz"
                  sh.cmd "curl -Lo /tmp/#{r_filename} #{r_url}", retry: true
                  sh.cmd "tar xJf /tmp/#{r_filename} -C ~"
                  sh.export 'PATH', "$HOME/R-bin/bin:$PATH"
                  sh.export 'LD_LIBRARY_PATH', "$HOME/R-bin/lib:$LD_LIBRARY_PATH"
                  sh.rm "/tmp/#{r_filename}"
                end

                # If on trusty just use the ubuntu package
                sh.if '$(lsb_release -cs) == "trusty"' do
                  # Install an R development environment. qpdf is also needed for
                  # --as-cran checks:
                  #   https://stat.ethz.ch/pipermail/r-help//2012-September/335676.html
                  sh.cmd 'sudo apt-get install -y --no-install-recommends r-base-dev ' +
                    'r-recommended qpdf texinfo', retry: true

                  # Change permissions for /usr/local/lib/R/site-library
                  # This should really be via 'sudo adduser travis staff'
                  # but that may affect only the next shell
                  sh.cmd 'sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library'
                end
                sh.cmd "sudo mkdir -p /usr/local/lib/R/site-library $R_LIBS_USER"
                sh.cmd 'sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library $R_LIBS_USER'
              when 'osx'
                # We want to update, but we don't need the 800+ lines of
                # output.
                sh.cmd 'brew update >/dev/null', retry: true

                # Install from latest CRAN binary build for OS X
                sh.cmd "wget #{repos[:CRAN]}/bin/macosx/R-latest.pkg "\
                  '-O /tmp/R-latest.pkg'

                sh.echo 'Installing OS X binary package for R'
                sh.cmd 'sudo installer -pkg "/tmp/R-latest.pkg" -target /'
                sh.rm '/tmp/R-latest.pkg'

              else
                sh.failure "Operating system not supported: #{config[:os]}"
              end

              # Set repos in ~/.Rprofile
              repos_str = repos.collect {|k,v| "#{k} = \"#{v}\""}.join(", ")
              options_repos = "options(repos = c(#{repos_str}))"
              sh.cmd %Q{echo '#{options_repos}' > ~/.Rprofile.site}

              setup_latex

              setup_bioc if needs_bioc?
              setup_pandoc if config[:pandoc]
            end
          end
        end

        def announce
          super
          sh.fold 'R-session-info' do
            sh.echo 'R session information', ansi: :yellow
            sh.cmd 'Rscript -e \'sessionInfo()\''
          end
        end

        def install
          super
          unless setup_cache_has_run_for[:r]
            setup_cache
          end

          sh.fold "R-dependencies" do
            sh.echo 'Installing package dependencies', ansi: :yellow

            # Install any declared packages
            apt_install config[:apt_packages]
            brew_install config[:brew_packages]
            r_binary_install config[:r_binary_packages]
            r_install config[:r_packages]
            r_install config[:bioc_packages]
            r_github_install config[:r_github_packages]

            # Install dependencies for the package we're testing.
            install_deps
          end
        end

        def script
          # Build the package
          sh.fold 'R-build' do
            sh.echo 'Building package', ansi: :yellow
            sh.echo "Building with: R CMD build ${R_BUILD_ARGS}"
            sh.cmd "R CMD build #{config[:r_build_args]} .",
                   assert: true

            tarball_script =
              'pkg <- devtools::as.package(".");'\
              'cat(paste0(pkg$package, "_", pkg$version, ".tar.gz"));'

            sh.export 'PKG_TARBALL', "$(Rscript -e '#{tarball_script}')"
          end

          # Build the package
          sh.fold 'R-check' do
            sh.echo 'Checking package', ansi: :yellow
            # Test the package
            sh.echo 'Checking with: R CMD check "${PKG_TARBALL}" '\
              "#{config[:r_check_args]}"
            sh.cmd "R CMD check \"${PKG_TARBALL}\" #{config[:r_check_args]}; "\
              "CHECK_RET=$?", assert: false
          end
          export_rcheck_dir

          # Output check summary
          sh.cmd 'Rscript -e "cat(devtools::check_failures(path = \"${RCHECK_DIR}\"), \"\\\n\")"', echo: false

          # Build fails if R CMD check fails
          sh.if '$CHECK_RET -ne 0' do
            dump_logs
            sh.failure 'R CMD check failed'
          end

          # Turn warnings into errors, if requested.
          if config[:warnings_are_errors]
            sh.cmd 'grep -q -R "WARNING" "${RCHECK_DIR}/00check.log"', echo: false, assert: false
            sh.if '$? -eq 0' do
              dump_logs
              sh.failure "Found warnings, treating as errors (as requested)."
            end
          end

          # Check revdeps, if requested.
          if config[:r_check_revdep]
            sh.echo "Checking reverse dependencies"
            revdep_script =
              'library("devtools");'/
              'res <- revdep_check();'/
              'if (length(res) > 0) {'/
              ' revdep_check_summary(res);'/
              ' revdep_check_save_logs(res);'/
              ' q(status = 1, save = "no");'/
              '}'
            sh.cmd "Rscript -e '#{revdep_script}'", assert: true
          end

        end

        def setup_cache
          return if setup_cache_has_run_for[:r]

          if data.cache?(:packages)
            sh.fold 'package cache' do
              sh.echo 'Setting up package cache', ansi: :yellow
              directory_cache.add '$R_LIBS_USER'
            end
          end
          setup_cache_has_run_for[:r] = true
        end

        def cache_slug
          super << '--R-' << r_version
        end

        def use_directory_cache?
          super || data.cache?(:packages)
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
          install_script =
            "install.packages(#{pkg_arg});"\
            "if (!all(#{pkg_arg} %in% installed.packages())) {"\
            ' q(status = 1, save = "no")'\
            '}'
          sh.cmd "Rscript -e '#{install_script}'"
        end

        def r_github_install(packages)
          return if packages.empty?
          setup_devtools
          sh.echo "Installing R packages from GitHub: #{packages.join(', ')}"
          pkg_arg = packages_as_arg(packages)
          install_script = "devtools::install_github(#{pkg_arg}, build_vignettes = FALSE)"
          sh.cmd "Rscript -e '#{install_script}'"
        end

        def r_binary_install(packages)
          return if packages.empty?
          if config[:os] == 'linux'
            unless config[:sudo]
              sh.echo "R binary packages not supported with 'sudo: false', "\
                ' falling back to source install'
              return r_install packages
            end
            sh.echo "Installing *binary* R packages: #{packages.join(', ')}"
            apt_install packages.collect{|p| "r-cran-#{p.downcase}"}
          else
            sh.echo "R binary packages not supported on #{config[:os]}, "\
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

        def install_deps
          setup_devtools
          install_script =
            'deps <- devtools::install_deps(dependencies = TRUE);'\
            'if (!all(deps %in% installed.packages())) {'\
            ' message("missing: ", paste(setdiff(deps, installed.packages()), collapse=", "));'\
            ' q(status = 1, save = "no")'\
            '}'
          sh.cmd "Rscript -e '#{install_script}'"
        end

        def export_rcheck_dir
          pkg_script = 'cat(paste0(devtools::as.package(".")$package, ".Rcheck"))'
          sh.export 'RCHECK_DIR', "$(Rscript -e '#{pkg_script}')", echo: false
        end

        def dump_logs
          sh.fold "Check logs" do
            export_rcheck_dir
            sh.echo 'R CMD check logs', ansi: :yellow
            ['out', 'log', 'fail'].each do |ext|
              cmd =
                'for name in '\
                "$(find \"${RCHECK_DIR}\" -type f -name \"*#{ext}\");"\
              'do '\
                'echo ">>> Filename: ${name} <<<";'\
                'cat ${name};'\
                'done'
              sh.cmd cmd
            end
          end
        end

        def setup_bioc
          unless @bioc_installed
            sh.fold 'Bioconductor' do
              sh.echo 'Installing Bioconductor', ansi: :yellow
              bioc_install_script =
                "source(\"#{config[:bioc]}\");"\
                'tryCatch('\
                " useDevel(#{as_r_boolean(config[:bioc_use_devel])}),"\
                ' error=function(e) {if (!grepl("already in use", e$message)) {e}}'\
                  ');'\
                  'cat(append = TRUE, file = "~/.Rprofile.site", "options(repos = BiocInstaller::biocinstallRepos());")'
                sh.cmd "Rscript -e '#{bioc_install_script}'", retry: true
            end
          end
          @bioc_installed = true
        end

        def setup_devtools
          unless @devtools_installed
            case config[:os]
            when 'linux'
              if config[:sudo]
                r_binary_install ['devtools']
              else
                r_install ['devtools']
              end
            else
              devtools_check = '!requireNamespace("devtools", quietly = TRUE)'
              devtools_install = 'install.packages("devtools")'
              sh.cmd "Rscript -e 'if (#{devtools_check}) #{devtools_install}'",
                     retry: true
            end
          end
          @devtools_installed = true
        end

        def setup_latex
          case config[:os]
          when 'linux'
            texlive_filename = 'texlive.tar.gz'
            texlive_url = 'https://github.com/yihui/ubuntu-bin/releases/download/latest/texlive.tar.gz'
            sh.cmd "curl -Lo /tmp/#{texlive_filename} #{texlive_url}"
            sh.cmd "tar xzf /tmp/#{texlive_filename} -C ~"
            sh.export 'PATH', "/$HOME/texlive/bin/x86_64-linux:$PATH"
            sh.cmd 'tlmgr update --self'
          when 'osx'
            # We use basictex due to disk space constraints.
            mactex = 'BasicTeX.pkg'
            # TODO(craigcitro): Confirm that this will route us to the
            # nearest mirror.
            sh.cmd 'wget http://mirror.ctan.org/systems/mac/mactex/'\
                   "#{mactex} -O \"/tmp/#{mactex}\""

            sh.echo 'Installing OS X binary package for MacTeX'
            sh.cmd "sudo installer -pkg \"/tmp/#{mactex}\" -target /"
            sh.rm "/tmp/#{mactex}"
            sh.export 'PATH', '/usr/texbin:$PATH'

            # set tlpkg writable so no sudo is needed
            ch.cmd "sudo 757 /usr/local/texlive/2015/tlpkg/"
            sh.cmd 'tlmgr update --self'

            # Install common packages
            sh.cmd 'tlmgr install inconsolata upquote '\
              'courier courier-scaled helvetic'
          end
        end

        def setup_pandoc
          case config[:os]
          when 'linux'
            pandoc_filename = "pandoc-#{config[:pandoc_version]}-1-amd64.deb"
            pandoc_url = "https://github.com/jgm/pandoc/releases/download/#{config[:pandoc_version]}/"\
              "#{pandoc_filename}"

            # Download and install pandoc
            sh.cmd "curl -Lo /tmp/#{pandoc_filename} #{pandoc_url}"
            sh.cmd "sudo dpkg -i /tmp/#{pandoc_filename}"

            # Fix any missing dependencies
            sh.cmd "sudo apt-get install -f"

            # Cleanup
            sh.rm "/tmp/#{pandoc_filename}"
          when 'osx'
            pandoc_filename = "pandoc-#{config[:pandoc_version]}-osx.pkg"
            pandoc_url = "https://github.com/jgm/pandoc/releases/download/#{config[:pandoc_version]}/"\
              "#{pandoc_filename}"

            # Download and install pandoc
            sh.cmd "curl -Lo /tmp/#{pandoc_filename} #{pandoc_url}"
            sh.cmd "sudo installer -pkg \"/tmp/#{pandoc_filename}\""

            # Cleanup
            sh.rm "/tmp/#{pandoc_filename}"
          end
        end

        def r_version
          @r_version ||= normalized_r_version
        end

        def normalized_r_version
          v = config[:r].to_s
          case v
          when 'release' then '3.2.3'
          when 'oldrel' then '3.1.3'
          when '3.1' then '3.1.3'
          when '3.2' then '3.2.3'
          else v
          end
        end

        def repos
          @repos ||= normalized_repos
        end

        # If CRAN is not set in repos set it with cran
        def normalized_repos
          v = config[:repos]
          if not v.has_key?(:CRAN)
            v[:CRAN] = config[:cran]
          end
          # If the version is less than 3.2 we need to use http repositories
          if r_version < '3.2'
            v.each {|_, url| url.sub!(/^https:/, "http:")}
            config[:bioc].sub!(/^https:/, "http:")
          end
          v
        end
      end
    end
  end
end
