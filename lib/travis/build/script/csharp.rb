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
          dotnet: 'none'
        }

        def config_dotnet
          config[:dotnet].to_s
        end

        def config_mono
          config[:mono].to_s
        end

        def config_os
          config[:os].to_s
        end

        def config_solution
          config[:solution].to_s if config[:solution]
        end

        MONO_VERSION_REGEXP   = /^(\d{1})\.(\d{1,2})\.\d{1,2}$/
        DOTNET_VERSION_REGEXP = /^(\d{1})\.(\d{1,2})\.\d{1,2}$/

        def configure
          super

          sh.echo ''
          sh.echo 'C# support for Travis-CI is community maintained.', ansi: :red
          sh.echo 'Please open any issues at https://github.com/travis-ci/travis-ci/issues/new and cc @joshua-anderson @akoeplinger @nterry', ansi: :red

          install_mono if is_mono_enabled
          install_dotnet if is_dotnet_enabled
        end

        def install_mono
          if !is_mono_version_valid?
            sh.failure "\"#{config_mono()}\" is either an invalid version of \"mono\" or unsupported on this operating system.
View valid versions of \"mono\" at https://docs.travis-ci.com/user/languages/csharp/"
          end

          sh.fold('mono-install') do
            sh.echo 'Installing Mono', ansi: :yellow
            case config_os
            when 'linux'
              if is_mono_2_10_8
                sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc', timing: true, assert: true
              elsif is_mono_3_2_8
                sh.cmd 'sudo apt-add-repository ppa:directhex/ppa -y', assert: true # Official ppa of the mono debian maintainer
                sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc fsharp', timing: true, assert: true
              else
                sh.cmd 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF', assert: true

                if is_mono_after_5_0
                  # new Mono repo layout
                  repo_prefix = 'alpha-' if config_mono == 'alpha' || config_mono == 'nightly' || config_mono == 'weekly'
                  repo_prefix = 'beta-'  if config_mono == 'beta'
                  repo_suffix = "/snapshots/#{config_mono}" if !is_mono_version_keyword?

                  # main packages
                  sh.if '$(lsb_release -cs) = precise' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu #{repo_prefix}precise#{repo_suffix} main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                  end
                  sh.elif '$(lsb_release -cs) = trusty' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu #{repo_prefix}trusty#{repo_suffix} main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                  end
                  sh.elif '$(lsb_release -cs) = xenial' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu #{repo_prefix}xenial#{repo_suffix} main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                  end
                  sh.else do
                    sh.failure "The version of this operating system is not supported by Mono. View valid versions at https://docs.travis-ci.com/user/languages/csharp/"
                  end

                  # nightly packages
                  if config_mono == 'nightly' || config_mono == 'weekly'
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu nightly main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true
                  end
                else
                  # old Mono repo layout
                  sh.if '$(lsb_release -cs) = precise' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy-libtiff-compat main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                  end

                  sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy/snapshots/#{config_mono} main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true
                end

                sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
                sh.cmd "sudo apt-get install -qq mono-complete mono-vbnc fsharp nuget #{'referenceassemblies-pcl' if !is_mono_3_8_0}", timing: true, assert: true
                                                                                      # PCL Assemblies only supported on mono 3.10 and greater
              end
            when 'osx'
              sh.cmd "wget --retry-connrefused --waitretry=1 -O /tmp/mdk.pkg #{mono_osx_url}", timing: true, assert: true, echo: true
              sh.cmd 'sudo installer -package "/tmp/mdk.pkg" -target "/" -verboseR', timing: true, assert: true
              sh.cmd 'eval $(/usr/libexec/path_helper -s)', timing: false, assert: true
            else
              sh.failure "Operating system not supported: #{config_os}"
            end

            if is_mono_before_3_12 && config_os == 'linux'
              # we need to fetch an ancient version of certdata (from 2009) because newer versions run into a Mono bug: https://github.com/mono/mono/pull/1514
              # this is the same file that was used in the old mozroots before https://github.com/mono/mono/pull/3188 so nothing really changes (but still less than ideal)
              sh.cmd 'wget --retry-connrefused --waitretry=1 -O /tmp/certdata.txt https://hg.mozilla.org/releases/mozilla-release/raw-file/5d447d9abfdf/security/nss/lib/ckfw/builtins/certdata.txt'
              sh.cmd 'mozroots --import --sync --quiet --file /tmp/certdata.txt', timing: true
            end
          end
        end

        def install_dotnet
          if !is_dotnet_version_valid?
            sh.failure "\"#{config_dotnet}\" is either an invalid version of \"dotnet\" or unsupported on this operating system.
View valid versions of \"dotnet\" at https://docs.travis-ci.com/user/languages/csharp/"
          end

          sh.fold('dotnet-install') do
            sh.echo 'Installing .NET Core', ansi: :yellow

            # the nuget cache initialization on first run doesn't make sense on Travis since it'd be cleared after the build is done
            sh.export 'DOTNET_SKIP_FIRST_TIME_EXPERIENCE', '1'

            # opt out of dotnet-cli telemetry
            sh.export 'DOTNET_CLI_TELEMETRY_OPTOUT', '1'

            case config_os
            when 'linux'
              sh.cmd 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BE1229CF', assert: true
              sh.if '$(lsb_release -cs) = trusty' do
                sh.cmd "sudo sh -c \"echo 'deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-trusty-prod trusty main' > /etc/apt/sources.list.d/dotnetdev.list\"", assert: true
              end
              sh.elif '$(lsb_release -cs) = xenial' do
                sh.cmd "sudo sh -c \"echo 'deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main' > /etc/apt/sources.list.d/dotnetdev.list\"", assert: true
              end
              sh.else do
                sh.failure "The version of this operating system is not supported by .NET Core. View valid versions at https://docs.travis-ci.com/user/languages/csharp/"
              end
              sh.cmd 'sudo apt-get update -qq', timing: true, assert: true
              sh.cmd "sudo apt-get install -qq dotnet-#{dotnet_package_prefix}-#{config_dotnet}", timing: true, assert: true
            when 'osx'
              min_osx_minor = 11
              min_osx_minor = 12 if is_dotnet_after_2_0?
              sh.if "$(sw_vers -productVersion | cut -d . -f 2) -lt #{min_osx_minor}" do
                sh.failure "The version of this operating system is not supported by .NET Core. View valid versions at https://docs.travis-ci.com/user/languages/csharp/"
              end
              if !is_dotnet_after_2_0?
                sh.cmd 'brew update', timing: true, assert: true
                sh.cmd 'brew install openssl', timing: true, assert: true
                sh.cmd 'mkdir -p /usr/local/lib', timing: false, assert: true
                sh.cmd 'ln -s /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib /usr/local/lib/', timing: false, assert: true
                sh.cmd 'ln -s /usr/local/opt/openssl/lib/libssl.1.0.0.dylib /usr/local/lib/', timing: false, assert: true
              end
              sh.cmd "wget --retry-connrefused --waitretry=1 -O /tmp/dotnet.pkg #{dotnet_osx_url}", timing: true, assert: true, echo: true
              sh.cmd 'sudo installer -package "/tmp/dotnet.pkg" -target "/" -verboseR', timing: true, assert: true
              sh.cmd 'eval $(/usr/libexec/path_helper -s)', timing: false, assert: true
            else
              sh.failure "Operating system not supported: #{config_os}"
            end
          end
        end

        def announce
          super

          sh.cmd 'mono --version', timing: true if is_mono_enabled
          sh.cmd "#{mono_build_cmd} /version", timing: true if is_mono_enabled
          sh.echo ''

          sh.cmd 'dotnet --info', timing: true if is_dotnet_enabled
          sh.echo ''
        end

        def export
          super

          sh.export 'TRAVIS_SOLUTION', config_solution.shellescape if config_solution
        end

        def install
          sh.cmd "nuget restore #{config_solution}", retry: true if is_mono_enabled && config_solution && !is_mono_2_10_8 && !is_mono_3_2_8
        end

        def script
          if config_solution && is_mono_enabled
            sh.cmd "#{mono_build_cmd} /p:Configuration=Release #{config_solution}", timing: true
          else
            sh.failure 'No solution or script defined, exiting'
          end
        end

        def mono_osx_url
          base_url = 'http://download.mono-project.com/archive/'

          case config_mono
          when 'latest'
            return base_url + 'mdk-latest.pkg'
          when 'alpha'
            return base_url + 'mdk-latest-alpha.pkg'
          when 'beta'
            return base_url + 'mdk-latest-beta.pkg'
          when 'weekly', 'nightly'
            return base_url + 'mdk-latest-weekly.pkg'
          else
            if is_mono_after_4_4
              return base_url + config_mono + "/macos-10-universal/MonoFramework-MDK-#{config_mono}.macos10.xamarin.universal.pkg"
            else
              return base_url + config_mono + "/macos-10-x86/MonoFramework-MDK-#{config_mono}.macos10.xamarin.x86.pkg"
            end
          end
        end

        def dotnet_osx_url
          if is_dotnet_after_2_0?
            return "https://dotnetcli.azureedge.net/dotnet/Sdk/#{config_dotnet}/dotnet-#{dotnet_package_prefix}-#{config_dotnet}-osx-x64.pkg"
          else
            return "https://dotnetcli.azureedge.net/dotnet/Sdk/#{config_dotnet}/dotnet-#{dotnet_package_prefix}-osx-x64.#{config_dotnet}.pkg"
          end
        end

        def dotnet_package_prefix
          return is_dotnet_after_2_0? ? "sdk" : "dev"
        end

        def mono_build_cmd
          is_mono_after_5_0 ? "msbuild" : "xbuild" 
        end

        def is_mono_version_valid?
          return false unless config_os == 'linux' || config_os == 'osx'
          return true if is_mono_version_keyword?
          return false unless MONO_VERSION_REGEXP === config_mono

          return false if MONO_VERSION_REGEXP.match(config_mono)[1] == '2' && !is_mono_2_10_8 && config_os == 'linux'
          return false if MONO_VERSION_REGEXP.match(config_mono)[1].to_i < 2 && config_os == 'linux'

          true
        end

        def is_dotnet_version_valid?
          return false unless config_os == 'linux' || config_os == 'osx'
          return false unless DOTNET_VERSION_REGEXP === config_dotnet

          true
        end

        def is_mono_enabled
          config_mono != 'none'
        end

        def is_dotnet_enabled
          config_dotnet != 'none'
        end

        def is_mono_version_keyword?
          ['latest', 'alpha', 'beta', 'weekly', 'nightly', 'none'].include? config_mono
        end

        def is_mono_2_10_8
          config_mono == '2.10.8'
        end

        def is_mono_3_2_8
          config_mono == '3.2.8'
        end

        def is_mono_3_8_0
          config_mono == '3.8.0'
        end

        def is_mono_before_3_12
          return false unless is_mono_version_valid?
          return false if is_mono_version_keyword?

          return true if MONO_VERSION_REGEXP.match(config_mono)[1] == '2'
          return true if MONO_VERSION_REGEXP.match(config_mono)[1] == '3' && MONO_VERSION_REGEXP.match(config_mono)[2].to_i < 12

          false
        end

        def is_mono_after_4_4
          return false unless is_mono_version_valid?
          return true if is_mono_version_keyword?

          return false if MONO_VERSION_REGEXP.match(config_mono)[1].to_i < 4
          return false if MONO_VERSION_REGEXP.match(config_mono)[1] == '4' && MONO_VERSION_REGEXP.match(config_mono)[2].to_i < 4

          true
        end

        def is_mono_after_5_0
          return false unless is_mono_version_valid?
          return true if is_mono_version_keyword?

          return false if MONO_VERSION_REGEXP.match(config_mono)[1].to_i < 5

          true
        end

        def is_dotnet_after_2_0?
          return false unless is_dotnet_version_valid?

          return false if DOTNET_VERSION_REGEXP.match(config_dotnet)[1].to_i < 2

          true
        end
      end
    end
  end
end
