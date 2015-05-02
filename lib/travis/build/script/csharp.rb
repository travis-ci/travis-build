# Maintained by:
# Joshua Anderson     @joshua-anderson j@joshua-anderson.com
# Alexander Köplinger @akoeplinger     alex.koeplinger@outlook.com
# Nicholas Terry      @nterry          nick.i.terry@gmail.com

module Travis
  module Build
    class Script
      class Csharp < Script
        DEFAULTS = {
          mono: 'latest',
        }

        MONO_VERSION_REGEXP = /^(\d{1})\.(\d{1,2})\.\d{1,2}$/

        def configure
          super

          sh.echo ''
          sh.echo 'C# support for Travis-CI is community maintained.', ansi: :red
          sh.echo 'Please open any issues at https://github.com/travis-ci/travis-ci/issues/new and cc @joshua-anderson @akoeplinger @nterry', ansi: :red


          sh.fold('mono-install') do
            if mono_version_valid?
              sh.echo 'Installing Mono', ansi: :yellow

              if is_mono_2_10_8
                sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc', timing: true, assert: true
              elsif is_mono_3_2_8
                sh.cmd 'sudo apt-add-repository ppa:directhex/ppa -y', assert: true # Official ppa of the mono debian maintainer
                sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc fsharp', timing: true, assert: true
              else
                sh.cmd 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF', echo: false, assert: true
                sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian #{mono_repo} main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", echo: false, assert: true
                sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy-libtiff-compat main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", echo: false, assert: true
                sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                sh.cmd "sudo apt-get install -qq mono-complete mono-vbnc fsharp nuget #{'referenceassemblies-pcl' if !is_mono_3_8_0}", timing: true, assert: true
                                                                                      # PCL Assemblies only supported on mono 3.10 and greater
              end

              sh.cmd 'mozroots --import --sync --quiet', timing: true
            end
          end
        end

        def setup
          super

          unless mono_version_valid?
            sh.echo "\"#{config[:mono]}\" is not a valid version of mono.", ansi: :red
            sh.cmd 'false', echo: false, timing: false
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
          sh.cmd "nuget restore #{config[:solution]}", retry: true if config[:solution] && !is_mono_2_10_8 && !is_mono_3_2_8
        end

        def script
          if config[:solution]
            sh.cmd "xbuild /p:Configuration=Release #{config[:solution]}", timing: true
          else
            sh.echo 'No solution or script defined, exiting', ansi: :red
            sh.cmd 'false', echo: false, timing: false
          end
        end

        def mono_repo
          if config[:mono] == 'latest'
            'wheezy'
          else
            'wheezy/snapshots/' << config[:mono]
          end
        end

        def mono_version_valid?
          return true if config[:mono] == 'latest'
          return false unless MONO_VERSION_REGEXP === config[:mono]

          return false if MONO_VERSION_REGEXP.match(config[:mono])[1] == '2' && !is_mono_2_10_8
          return false if MONO_VERSION_REGEXP.match(config[:mono])[1].to_i < 2

          true
        end

        def is_mono_2_10_8
          config[:mono] == '2.10.8'
        end

        def is_mono_3_2_8
          config[:mono] == '3.2.8'
        end

        def is_mono_3_8_0
          config[:mono] == '3.8.0'
        end
      end
    end
  end
end
