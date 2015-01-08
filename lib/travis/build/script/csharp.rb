# Maintained by:
# Joshua Anderson     @joshua-anderson j@joshua-anderson.com
# Alexander Köplinger @akoeplinger     alex.koeplinger@outlook.com
# Nicholas Terry      @nterry          nick.i.terry@gmail.com

module Travis
  module Build
    class Script
      class Csharp < Script
        DEFAULTS = {
          csharp: 'mono',
        }

        def configure
          super

          sh.echo ''
          sh.echo 'BETA Warning: Travis-CI C# support is in beta and may be changed or removed at any time.', ansi: :red
          sh.echo 'Please open any issues at https://github.com/travis-ci/travis-ci/issues/new and cc @joshua-anderson @akoeplinger @nterry', ansi: :red


          sh.fold('mono-install') do
            if config[:csharp] == 'mono'
              sh.echo 'Installing Mono', ansi: :yellow

              sh.cmd 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF', echo: false
              sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", echo: false
              sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy-libtiff-compat main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", echo: false
              sh.cmd 'sudo apt-get update -qq', timing: true
              sh.cmd 'sudo apt-get install -qq mono-complete referenceassemblies-pcl nuget mono-vbnc fsharp', timing: true
              sh.cmd 'mozroots --import --sync --quiet', timing: true
            end
          end
        end

        def announce
          super

          sh.cmd 'mono --version', timing: true
          sh.cmd 'xbuild /version', timing: true
          sh.echo ''
        end

        def export
          super

          sh.export 'TRAVIS_SOLUTION', config[:solution].to_s.shellescape if config[:solution]
        end

        def install
          sh.cmd "nuget restore #{config[:solution]}", retry: true if config[:solution]
        end

        def script
          if config[:solution]
            sh.cmd "xbuild /p:Configuration=Release #{config[:solution]}", timing: true if config[:solution]
          else
            sh.echo 'No solution or script defined, exiting', ansi: :red
            sh.cmd 'false', echo: false, timing: false
          end
        end
      end
    end
  end
end
