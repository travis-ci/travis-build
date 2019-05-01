# vim:set ts=2 sw=2 sts=2 autoindent:

# Community maintainers:
#
#   Alex Arslan       (@ararslan)
#   Elliot Saba       (@staticfloat)
#   Stefan Karpinski  (@StefanKarpinski)
#
module Travis
  module Build
    class Script
      class Julia < Script
        DEFAULTS = {
          julia: 'release',
          coveralls: false,
          codecov: false,
        }

        def export
          super

          sh.export 'TRAVIS_JULIA_VERSION', config[:julia].to_s.shellescape,
            echo: false
          sh.export 'JULIA_PROJECT', "@."
        end

        def setup
          super

          sh.echo 'Julia for Travis-CI is not officially supported, ' \
            'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
            ansi: :green
          sh.echo '  https://travis-ci.community/c/languages/julia', ansi: :green
          sh.echo 'and mention \`@ararslan\`, \`@staticfloat\`' \
            ' and \`@StefanKarpinski\` in the issue', ansi: :green

          sh.fold 'Julia-install' do
            sh.echo 'Installing Julia', ansi: :yellow
            sh.cmd 'CURL_USER_AGENT="Travis-CI $(curl --version | head -n 1)"'
            case config[:os]
            when 'linux'
              sh.cmd 'mkdir -p ~/julia'
              sh.cmd %Q{curl -A "$CURL_USER_AGENT" -s -L --retry 7 '#{julia_url}' } \
                       '| tar -C ~/julia -x -z --strip-components=1 -f -'
            when 'osx'
              sh.cmd %Q{curl -A "$CURL_USER_AGENT" -s -L --retry 7 -o julia.dmg '#{julia_url}'}
              sh.cmd 'mkdir juliamnt'
              sh.cmd 'hdiutil mount -readonly -mountpoint juliamnt julia.dmg'
              sh.cmd 'cp -a juliamnt/*.app/Contents/Resources/julia ~/'
            else
              sh.failure "Operating system not supported: #{config[:os]}"
            end
            sh.cmd 'export PATH="${PATH}:${TRAVIS_HOME}/julia/bin"'
          end
        end

        def announce
          super

          sh.cmd 'julia --color=yes -e "VERSION >= v\"0.7.0-DEV.3630\" && using InteractiveUtils; versioninfo()"'
          sh.newline
        end

        def script
          sh.echo 'Executing the default test script', ansi: :green

          # Extract the package name from the repository slug (org/pkgname.jl)
          m = /(\w+?)\/(\w+?)(?:\.jl)?$/.match(data[:repository][:slug])
          if m != nil
            sh.export 'JL_PKG', m[2]
          end
          sh.echo 'Package name determined from repository url to be ${JL_PKG}',
            ansi: :green
          # Check if the repository is using new Pkg
          sh.if "-f Project.toml || -f JuliaProject.toml" do
            sh.if '-a .git/shallow' do
              sh.cmd 'git fetch --unshallow'
            end
            # build
            sh.cmd 'julia --color=yes -e "if VERSION < v\"0.7.0-DEV.5183\"; Pkg.clone(pwd()); Pkg.build(\"${JL_PKG}\"); else using Pkg; if VERSION >= v\"1.1.0-rc1\"; Pkg.build(verbose=true); else Pkg.build(); end; end"', assert: true
            # run tests
            sh.cmd 'julia --check-bounds=yes --color=yes -e "if VERSION < v\"0.7.0-DEV.5183\"; Pkg.test(\"${JL_PKG}\", coverage=true); else using Pkg; Pkg.test(coverage=true); end"', assert: true
            # coverage
            if config[:codecov]
              sh.cmd 'julia --color=yes -e "if VERSION < v\"0.7.0-DEV.5183\"; cd(Pkg.dir(\"${JL_PKG}\")); else using Pkg; end; Pkg.add(\"Coverage\"); using Coverage; Codecov.submit(process_folder())"'
            end
            if config[:coveralls]
              sh.cmd 'julia --color=yes -e "if VERSION < v\"0.7.0-DEV.5183\"; cd(Pkg.dir(\"${JL_PKG}\")); else using Pkg; end; Pkg.add(\"Coverage\"); using Coverage; Coveralls.submit(process_folder())"'
            end

          end
          sh.else do
            sh.if '-a .git/shallow' do
              sh.cmd 'git fetch --unshallow'
            end
            # build
            sh.cmd 'julia --color=yes -e "VERSION >= v\"0.7.0-DEV.5183\" && using Pkg; Pkg.clone(pwd()); if VERSION >= v\"1.1.0-rc1\"; Pkg.build(\"${JL_PKG}\"; verbose=true); else Pkg.build(\"${JL_PKG}\"); end"', assert: true
            # run tests
            sh.cmd 'julia --check-bounds=yes --color=yes -e "VERSION >= v\"0.7.0-DEV.5183\" && using Pkg; Pkg.test(\"${JL_PKG}\", coverage=true)"', assert: true
            # coverage
            if config[:codecov]
              sh.cmd 'julia --color=yes -e "VERSION >= v\"0.7.0-DEV.5183\" && using Pkg; cd(Pkg.dir(\"${JL_PKG}\")); Pkg.add(\"Coverage\"); using Coverage; Codecov.submit(process_folder())"'
            end
            if config[:coveralls]
              sh.cmd 'julia --color=yes -e "VERSION >= v\"0.7.0-DEV.5183\" && using Pkg; cd(Pkg.dir(\"${JL_PKG}\")); Pkg.add(\"Coverage\"); using Coverage; Coveralls.submit(process_folder())"'
            end
          end
        end

        private

          def julia_url
            case config[:os]
            when 'linux'
              osarch = 'linux/x64'
              ext = 'linux-x86_64.tar.gz'
              nightlyext = 'linux64.tar.gz'
            when 'osx'
              osarch = 'mac/x64'
              ext = 'mac64.dmg'
              nightlyext = ext
            end
            case julia_version = Array(config[:julia]).first.to_s
            when 'release'
              # CHANGEME on new minor releases (once or twice a year)
              url = "julialang-s3.julialang.org/bin/#{osarch}/0.6/julia-0.6-latest-#{ext}"
            when 'nightly'
              url = "julialangnightlies-s3.julialang.org/bin/#{osarch}/julia-latest-#{nightlyext}"
            when /^(\d+\.\d+)\.\d+$/
              url = "julialang-s3.julialang.org/bin/#{osarch}/#{$1}/julia-#{julia_version}-#{ext}"
            when /^(\d+\.\d+)$/
              url = "julialang-s3.julialang.org/bin/#{osarch}/#{$1}/julia-#{$1}-latest-#{ext}"
            else
              sh.failure "Unknown Julia version: #{julia_version}"
            end
            "https://#{url}"
          end
      end
    end
  end
end
