# vim:set ts=2 sw=2 sts=2 autoindent:

# Community maintainers:
#
#   Tony Kelman       <tony kelman net, @tkelman>
#   Pontus Stenetorp  <pontus stenetorp se, @ninjin>
#   Elliot Saba       <staticfloat gmail com, @staticfloat>
#
module Travis
  module Build
    class Script
      class Julia < Script
        DEFAULTS = {
          julia: 'release',
        }

        def export
          super

          sh.export 'TRAVIS_JULIA_VERSION', config[:julia].to_s.shellescape,
            echo: false
        end

        def setup
          super

          sh.echo 'Julia for Travis-CI is not officially supported, ' \
            'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
            ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues' \
            '/new?labels=julia', ansi: :green
          sh.echo 'and mention \`@tkelman\`, \`@ninjin\` and ' \
            '\`@staticfloat\` in the issue', ansi: :green

          sh.echo 'Installing Julia', ansi: :yellow
          case config[:os]
          when 'linux'
            sh.cmd 'mkdir -p ~/julia'
            sh.cmd %Q{curl -s -L --retry 7 '#{julia_url}' } \
              '| tar -C ~/julia -x -z --strip-components=1 -f -'
          when 'osx'
            sh.cmd %Q{curl -s -L -o julia.dmg '#{julia_url}'}
            sh.cmd 'hdiutil mount -readonly julia.dmg'
            sh.cmd 'cp -a /Volumes/Julia/*.app/Contents/Resources/julia ~/'
          else
            sh.failure "Operating system not supported: #{config[:os]}"
          end
          sh.cmd 'export PATH="${PATH}:${HOME}/julia/bin"'
        end

        def announce
          super

          sh.cmd "julia -e 'versioninfo()'"
          sh.echo ''
        end

        def script
          sh.echo 'Executing the default test script', ansi: :green
          set_jl_pkg
          # Check if the repository is a Julia package.
          sh.if "-f src/${JL_PKG}.jl" do
            sh.if '-a .git/shallow' do
              sh.cmd 'git fetch --unshallow'
            end
            sh.cmd "julia -e 'Pkg.clone(pwd())'"
            sh.cmd 'julia -e "Pkg.build(\"${JL_PKG}\")"'
            sh.if '-f test/runtests.jl' do
              sh.cmd 'julia --check-bounds=yes ' \
                '-e "Pkg.test(\"${JL_PKG}\", coverage=true)"'
            end
          end
        end

        private

          def julia_url
            case config[:julia]
            when 'release'
              version = 'stable'
            when 'nightly'
              version = 'download'
            else
              sh.failure "Unknown Julia version: #{config[:julia]}"
            end
            case config[:os]
            when 'linux'
              os = 'linux-x86_64'
            when 'osx'
              os = 'osx10.7+'
            end
            "https://status.julialang.org/#{version}/#{os}"
          end

          def set_jl_pkg
            # Regular expression from: julia:base/pkg/entry.jl
            urlregex = 'r"(?:^|[/\\\\])(\w+?)(?:\.jl)?(?:\.git)?$"'
            jlcode = "println(match(#{urlregex}, readchomp(STDIN)).captures[1])"
            shurl = "git remote -v | head -n 1 | cut -f 2 | cut -f 1 -d ' '"
            sh.export 'JL_PKG', "$(#{shurl} | julia -e '#{jlcode}')",
              echo: false
          end
      end
    end
  end
end
