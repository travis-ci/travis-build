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
        DOTNET_VERSION_REGEXP = /^(?<major>\d{1})\.(?<minor>\d{1,2})(\.(?<patch>\d{1,3}))?(?<prerelease>-[\w-]+)?$/

        def configure
          super

          sh.newline
          sh.echo 'C# support for Travis-CI is community maintained.', ansi: :red
          sh.echo 'Please open any issues at https://travis-ci.community/c/languages/37-category and cc @joshua-anderson @akoeplinger @nterry', ansi: :red

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
                sh.cmd 'travis_apt_get_update', retry: true, timing: true, assert: true
                sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc', timing: true, assert: true
              elsif is_mono_3_2_8
                sh.cmd 'sudo apt-add-repository ppa:directhex/ppa -y', assert: true # Official ppa of the mono debian maintainer
                sh.cmd 'travis_apt_get_update', retry: true, timing: true, assert: true
                sh.cmd 'sudo apt-get install -qq mono-complete mono-vbnc fsharp', timing: true, assert: true
              else
                setup_pgp_key "mono"

                if is_mono_after_5_0
                  # new Mono repo layout
                  repo_prefix = is_mono_preview || is_mono_nightly ? 'preview-' : 'stable-'
                  repo_suffix = "/snapshots/#{config_mono}" if !is_mono_version_keyword?

                  # main packages
                  sh.if '$(lsb_release -cs) = precise' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu #{repo_prefix}precise#{repo_suffix} main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu nightly-precise main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true if is_mono_nightly
                  end
                  sh.elif '$(lsb_release -cs) = trusty' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu #{repo_prefix}trusty#{repo_suffix} main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu nightly-trusty main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true if is_mono_nightly
                  end
                  sh.elif '$(lsb_release -cs) = xenial' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu #{repo_prefix}xenial#{repo_suffix} main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu nightly-xenial main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true if is_mono_nightly
                  end
                  sh.elif '$(lsb_release -cs) = bionic' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu #{repo_prefix}bionic#{repo_suffix} main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/ubuntu nightly-bionic main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true if is_mono_nightly
                  end
                  sh.else do
                    sh.failure "The version of this operating system is not supported by Mono. View valid versions at https://docs.travis-ci.com/user/languages/csharp/"
                  end

                else
                  # old Mono repo layout
                  sh.if '$(lsb_release -cs) = precise' do
                    sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy-libtiff-compat main' > /etc/apt/sources.list.d/mono-official.list\"", assert: true
                  end

                  sh.cmd "sudo sh -c \"echo 'deb http://download.mono-project.com/repo/debian wheezy/snapshots/#{config_mono} main' >> /etc/apt/sources.list.d/mono-official.list\"", assert: true
                end

                sh.cmd 'travis_apt_get_update', retry: true, timing: true, assert: true
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
              setup_pgp_key "dotnet"
              sh.if '$(lsb_release -cs) = trusty' do
                sh.cmd "sudo sh -c \"echo 'deb [arch=amd64] https://packages.microsoft.com/ubuntu/14.04/prod trusty main' > /etc/apt/sources.list.d/dotnet-official.list\"", assert: true
              end
              sh.elif '$(lsb_release -cs) = xenial' do
                sh.cmd "sudo sh -c \"echo 'deb [arch=amd64] https://packages.microsoft.com/ubuntu/16.04/prod xenial main' > /etc/apt/sources.list.d/dotnet-official.list\"", assert: true
              end
              sh.elif '$(lsb_release -cs) = bionic' do
                sh.cmd "sudo sh -c \"echo 'deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod bionic main' > /etc/apt/sources.list.d/dotnet-official.list\"", assert: true
              end
              sh.else do
                sh.failure "The version of this operating system is not supported by .NET Core. View valid versions at https://docs.travis-ci.com/user/languages/csharp/"
              end
              sh.cmd 'travis_apt_get_update', retry: true, timing: true, assert: true
              sh.cmd "sudo apt-get install -qq dotnet-#{dotnet_package_prefix}-#{dotnet_package_version}", timing: true, assert: true
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
          sh.newline

          sh.cmd 'dotnet --info', timing: true if is_dotnet_enabled
          sh.newline
        end

        def export
          super

          sh.export 'TRAVIS_SOLUTION', config_solution.shellescape if config_solution
          sh.export 'STANDARD_CI_SOURCE_REVISION_ID', '${TRAVIS_COMMIT}', echo: false
          sh.export 'STANDARD_CI_REPOSITORY_URL', 'https://github.com/${TRAVIS_REPO_SLUG}', echo: false
          sh.export 'STANDARD_CI_REPOSITORY_TYPE', 'git', echo: false
        end

        def install
          sh.cmd "nuget restore #{config_solution.shellescape}", retry: true if is_mono_enabled && config_solution && !is_mono_2_10_8 && !is_mono_3_2_8
        end

        def script
          if config_solution && is_mono_enabled
            sh.cmd "#{mono_build_cmd} /p:Configuration=Release #{config_solution.shellescape}", timing: true
          else
            sh.failure 'No solution or script defined, exiting'
          end
        end

        def setup_pgp_key(key_type)
          if key_type == 'mono'
            pgp_key = mono_pgp_key
          elsif key_type == 'dotnet'
            pgp_key = dotnet_pgp_key
          else
            return
          end

          pgp_key.each_line do |line|
            sh.cmd "echo '#{line.chomp}' >> /tmp/#{key_type}.asc"
          end
          sh.cmd "gpg --dearmor < /tmp/#{key_type}.asc > /tmp/#{key_type}.gpg", assert: true
          sh.cmd "sudo mv /tmp/#{key_type}.gpg /etc/apt/trusted.gpg.d/", assert: true
        end

        def mono_pgp_key
          return "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
                 "Version: GnuPG v1\n" +
                 "\n" +
                 "mQENBFPfqCcBCADctOzyTxfWvf40Nlb+AMkcJyb505WSbzhWU8yPmBNAJOnbwueM\n" +
                 "sTkNMHEOu8fGRNxRWj5o/Db1N7EoSQtK3OgFnBef8xquUyrzA1nJ2aPfUWX+bhTG\n" +
                 "1TwyrtLaOssFRz6z/h/ChUIFvt2VZCw+Yx4BiKi+tvgwrHTYB/Yf2J9+R/1O6949\n" +
                 "n6veFFRBfgPOL0djhvRqXzhvFjJkh4xhTaGVeOnRR3+YQkblmti2n6KYl0n2kNB4\n" +
                 "0ujSqpTloSfnR5tmJpz00WoOA9MJBdvHtxTTn8l6rVzXbm4mW9ZmB1kht/BgWaNL\n" +
                 "aIisW5AZSkQKer35wOWf0G7Gw+cWHq+I7W9pABEBAAG0OlhhbWFyaW4gUHVibGlj\n" +
                 "IEplbmtpbnMgKGF1dG8tc2lnbmluZykgPHJlbGVuZ0B4YW1hcmluLmNvbT6JATgE\n" +
                 "EwECACIFAlPfqCcCGwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEKahmzjT\n" +
                 "2DHvkOgH/2Hmny7VxRLLoynY+ONbf3wsllqpbBprZb+VwsQo3uhZMLlh/kES5Ww7\n" +
                 "3bvSlWWf0K/uGKpxsLyTLCT6xm9Gxg7e6hNHCyYiZz/u5orfzaF7LUDaG+Qfl9ge\n" +
                 "Zj/ln9nRub8DSTRyGEbbJyNaNldgtn3ojRVTdkFAEeiHepG2BarjJZOwIkFf4Uo8\n" +
                 "F2aQimBw9dDD6FqTSaPawguqNJxFlPU575Ymww0xotrx1J3D6k+bw0z9UYuY72JN\n" +
                 "MMCm4CxGLGkJgt0lj5OEY2sp7rEOzBCjyCveBsGQmLTAtEM/ZHOrusPRMLY/E5pY\n" +
                 "5nuGbLP4SGMtyNmEc0lNpr41XSTxgDCJARwEEAECAAYFAlQIhKQACgkQyQ+cuQ4f\n" +
                 "rQyc1wf+MCusJK4ANLWikbgiSSx1qMBveBlLKLEdCxYY+B9rc/pRDw448iBdd+nu\n" +
                 "SVdbRoqLgoN8gHbClboP+i22yw+mga0KASD7b1mpdYB0npR3H73zbYArn3qTV8s/\n" +
                 "yUXkIAEFUtj0yoEuv8KjO8P7nZJh8OuqqAupUVN0s3KjONqXqi6Ro3fvVEZWOUFZ\n" +
                 "l/FmY5KmXlpcw+YwE5CaNhJ2WunrjFTDqynRU/LeoPEKuwyYvfo937zJFCrpAUMT\n" +
                 "r/9QpEKmV61H7fEHA9oHq97FBwWfjOU0l2mrXt1zJ97xVd2DXxrZodlkiY6B76rh\n" +
                 "aT4ZhltY1E7WB2Z9WPfTe1Y6jz4fZ7kBDQRT36gnAQgArXOx7LAvUtz8SZtcqLrx\n" +
                 "n2C4ZviszDvoCKMu0d9lVyGTca5DGM2nnq6krDMMXYRI8jrHE/qyW0RmfvYjzhno\n" +
                 "eAKmZc8zrsUPy4OYftphlV3tAL2/gNswuepi0kAi91vDYwAVGXZJ53NWCH/Q89OX\n" +
                 "8uIzxLbTUsvkc7XtCEyx9R8vzyga5ReZ/htf/On9y+Z9WWV5ld74vq10/zshIfcU\n" +
                 "UuLrJkepFYeKNlxpSM1K1I4Wb2+Jcax31oMypVhaFEsnWmQ5O3opEyhevdkYkkqS\n" +
                 "2wy1trDTnc09nqr9gfAiURebC2w+gQd3QGx+yn6iogk98XAmYTRGcPjPhnETvxzW\n" +
                 "5wARAQABiQEfBBgBAgAJBQJT36gnAhsMAAoJEKahmzjT2DHvrDUIAMI5vTyeObez\n" +
                 "QTU159c2naEEGz6s/agJVoiCNJPs8yQk01aoMiFyWCOs3TYgfzodV2o7P0/c/bS+\n" +
                 "ePiy6oLWSmtJcwzpnMZ+iLo392tTBXWMSoGkLU9gA8QIprgaM92NaIcV4ALNvlSE\n" +
                 "lmKDwSPlFoWKoNdc6t7sKRSGEAUYJFcnQsXnwsWNfaJDafRTwuyiT6SZDjYAwCuv\n" +
                 "d2PZjmV0qvl3hoY8t0sXrJdD2CyH1d98/rwqXNqNXQwOcLsnIH6rqTUCE5EJuoDz\n" +
                 "h9Yy7vFbbZuH3RLVTHKpJ/HSRaJqNyVt6sSOyFsI21UYNdBvCxgLgWw+ggNHRkn/\n" +
                 "D5BxWL9l7HU=\n" +
                 "=RDbl\n" +
                 "-----END PGP PUBLIC KEY BLOCK-----\n"
        end

        def dotnet_pgp_key
          return "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
                 "Version: GnuPG v1\n" +
                 "\n" +
                 "mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT\n" +
                 "LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV\n" +
                 "7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag\n" +
                 "OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j\n" +
                 "H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr\n" +
                 "M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs\n" +
                 "ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATUEEwEC\n" +
                 "AB8FAlYxWIwCGwMGCwkIBwMCBBUCCAMDFgIBAh4BAheAAAoJEOs+lK2+EinPGpsH\n" +
                 "/32vKy29Hg51H9dfFJMx0/a/F+5vKeCeVqimvyTM04C+XENNuSbYZ3eRPHGHFLqe\n" +
                 "MNGxsfb7C7ZxEeW7J/vSzRgHxm7ZvESisUYRFq2sgkJ+HFERNrqfci45bdhmrUsy\n" +
                 "7SWw9ybxdFOkuQoyKD3tBmiGfONQMlBaOMWdAsic965rvJsd5zYaZZFI1UwTkFXV\n" +
                 "KJt3bp3Ngn1vEYXwijGTa+FXz6GLHueJwF0I7ug34DgUkAFvAs8Hacr2DRYxL5RJ\n" +
                 "XdNgj4Jd2/g6T9InmWT0hASljur+dJnzNiNCkbn9KbX7J/qK1IbR8y560yRmFsU+\n" +
                 "NdCFTW7wY0Fb1fWJ+/KTsC4=\n" +
                 "=J6gs\n" +
                 "-----END PGP PUBLIC KEY BLOCK-----\n"
        end

        def mono_osx_url
          base_url = 'http://download.mono-project.com/archive/'

          case config_mono
          when 'latest'
            return base_url + 'mdk-latest.pkg'
          when 'alpha', 'beta', 'preview'
            return base_url + 'mdk-latest-preview.pkg'
          when 'weekly', 'nightly'
            return base_url + 'mdk-latest-nightly.pkg'
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

        def dotnet_package_version
          return config_dotnet unless is_dotnet_after_2_1_300? # before 2.1.300, the package ID contains the full version
          version = DOTNET_VERSION_REGEXP.match(config_dotnet)
          return config_dotnet unless version[:patch] # if only major.minor is provided

          "#{version[:major]}.#{version[:minor]}=#{config_dotnet}*" # if fully-qualified version is specified
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
          ['latest', 'alpha', 'beta', 'preview', 'weekly', 'nightly', 'none'].include? config_mono
        end

        def is_mono_nightly
          config_mono == 'nightly' || config_mono == 'weekly'
        end

        def is_mono_preview
          config_mono == 'alpha' || config_mono == 'beta' || config_mono == 'preview'
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

          return false if DOTNET_VERSION_REGEXP.match(config_dotnet)[:major].to_i < 2

          true
        end

        # Starting in 2.1.300, the package ID changed from dotnet-sdk-(major.minor.patch) to dotnet-sdk-(major.minor)
        def is_dotnet_after_2_1_300?
          return false unless is_dotnet_version_valid?
          return true if config_dotnet == '2.1' # Special case - treat '2.1' as >= 2.1.300
          Gem::Version.new(config_dotnet) >= Gem::Version.new('2.1.300')
        end
      end
    end
  end
end
