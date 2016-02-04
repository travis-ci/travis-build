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
              case config[:os]
              when 'linux'
                if is_mono_2_10_8
                  sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                  sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc', timing: true, assert: true
                elsif is_mono_3_2_8
                  sh.cmd 'sudo apt-add-repository ppa:directhex/ppa -y', assert: true # Official ppa of the mono debian maintainer
                  sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                  sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc fsharp', timing: true, assert: true
                else
                  sh.cmd 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF', echo: false, assert: true
                  sh.if '$(lsb_release -cs) = precise' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy-libtiff-compat main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", echo: false, assert: true
                  end
                  mono_repos.each do |repo|
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian #{repo} main' >> /etc/apt/sources.list.d/mono-xamarin.list\"", echo: false, assert: true
                  end
                  sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                  sh.cmd "sudo apt-get install -qq mono-complete mono-vbnc fsharp nuget #{'referenceassemblies-pcl' if !is_mono_3_8_0}", timing: true, assert: true
                                                                                        # PCL Assemblies only supported on mono 3.10 and greater
                end
              when 'osx'
                sh.cmd "curl -o \"/tmp/mdk.pkg\" -L #{mono_osx_url}", timing: true, assert: true
                sh.cmd 'sudo installer -package "/tmp/mdk.pkg" -target "/"', timing: true, assert: true
              else
                sh.failure "Operating system not supported: #{config[:os]}"
              end

              sh.cmd 'mozroots --import --sync --quiet', timing: true
            end
          end
        end

        def setup
          super

          unless mono_version_valid?
            sh.failure "\"#{config[:mono]}\" is either a invalid version of mono or unsupported on #{config[:os]}.
View valid versions of mono at https://docs.travis-ci.com/user/languages/csharp/"
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
            sh.failure 'No solution or script defined, exiting'
          end
        end

        def mono_repos
          repos = []

          case config[:mono]
          when 'latest'
            repos << 'wheezy'
          when 'alpha'
            repos << 'wheezy'
            repos << 'alpha'
          when 'beta'
            repos << 'wheezy'
            repos << 'beta'
          when 'weekly', 'nightly'  # nightly is a misnomer, but we need to keep it to avoid breaking existing scripts
            repos << 'wheezy'
            repos << 'nightly'
          else
            repos << "wheezy/snapshots/#{config[:mono]}"
          end

          repos
        end

        def mono_osx_url
          base_url = 'http://download.mono-project.com/archive/'

          case config[:mono]
          when 'latest'
            return base_url + 'mdk-latest.pkg'
          when 'alpha'
            return base_url + 'mdk-latest-alpha.pkg'
          when 'beta'
            return base_url + 'mdk-latest-beta.pkg'
          when 'weekly', 'nightly'
            return base_url + 'mdk-latest-weekly.pkg'
          else
            return base_url + config[:mono] + "/macos-10-x86/MonoFramework-MDK-#{config[:mono]}.macos10.xamarin.x86.pkg"
          end
        end

        def mono_version_valid?
          return true if ['latest', 'alpha', 'beta', 'weekly', 'nightly'].include? config[:mono]
          return false unless MONO_VERSION_REGEXP === config[:mono]

          return false if MONO_VERSION_REGEXP.match(config[:mono])[1] == '2' && !is_mono_2_10_8 && config[:os] == 'linux'
          return false if MONO_VERSION_REGEXP.match(config[:mono])[1].to_i < 2 && config[:os] == 'linux'

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
