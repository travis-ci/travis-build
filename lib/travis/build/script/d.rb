# Community maintainers:
#
#   Martin Nowak <code dawg eu, @MartinNowak>
#
module Travis
  module Build
    class Script
      class D < Script
        DEFAULTS = {
          d: 'dmd-2.066.1'
        }

        def cache_slug
          super << "--d-" << config[:d]
        end

        def export
          super
          sh.export 'DC', compiler_cmd
          sh.export 'DMD', dmd_cmd
        end

        def setup
          super

          sh.echo 'D support for Travis-CI is community maintained.'+
            'Please make sure to ping @MartinNowak, @klickverbot and @ibuclaw'+
            'when filing issues under https://github.com/travis-ci/travis-ci/issues.', ansi: :green

          sh.fold("compiler-download") do
            sh.echo "Installing compiler and dub", ansi: :yellow

            sh.cmd 'alias curl="curl -fsSL --retry 3 -A \'Travis-CI $(curl --version | head -n 1)\'"'
            case compiler_cmd
            when 'dmd'
              binpath, libpath = {'linux' => ['dmd2/linux/bin64', 'dmd2/linux/lib64'],
                                  'osx' => ['dmd2/linux/bin', 'dmd2/linux/lib']}[os]

              sh.cmd "curl #{compiler_url} > ~/dmd.zip"
              sh.cmd "unzip -q -d ~ ~/dmd.zip"
            when 'ldc2'
              binpath, libpath = 'ldc/bin', 'ldc/lib'

              sh.cmd "mkdir ${HOME}/ldc", echo: false
              sh.cmd "curl #{compiler_url} | tar --strip-components=1 -C ~/ldc -Jxf -"
            when 'gdc'
              binpath, libpath = 'gdc/bin', 'gdc/lib'

              sh.cmd "mkdir ${HOME}/gdc", echo: false
              sh.cmd "curl #{compiler_url} | tar --strip-components=1 -C ~/gdc -Jxf -"
              sh.cmd 'curl https://raw.githubusercontent.com/D-Programming-GDC/GDMD/master/dmd-script > '+
                "~/#{binpath}/gdmd && chmod +x ~/#{binpath}/gdmd"
            end

            sh.cmd 'LATEST_DUB=$('+
              'curl https://api.github.com/repos/D-Programming-Language/dub/tags | '+
              'sed -n \'s|.*"name": "v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)".*|\1|p\' |'+
              'sort | tail -n 1)', echo: false
            sh.cmd "curl http://code.dlang.org/files/dub-${LATEST_DUB}-#{os}-x86_64.tar.gz | tar -C ~/#{binpath} -xzf -"
            sh.cmd "export PATH=\"${HOME}/#{binpath}:${PATH}\""
            sh.cmd "export LD_LIBRARY_PATH=\"${HOME}/#{libpath}:${LD_LIBRARY_PATH}\""
          end
        end

        def announce
          super
          if compiler_cmd == 'dmd'
            sh.cmd 'dmd --help | head -n 2'
          else
            sh.cmd "#{compiler_cmd} --version"
          end
        end

        def script
          sh.cmd "dub test --compiler=#{compiler_cmd}"
        end

        private

        def os
          config[:os] || 'linux'
        end

        def compiler_url compiler=config[:d]
          case compiler
          # dmd-2.062, dmd-2.065.0, dmd-2.066.1-rc.3
          when /^dmd-2\.(\d{3}(\.\d(-.*)?)?)$/
            if $1.to_i <= 61
              "http://downloads.dlang.org/releases/2012/dmd.2.#{$1}.zip"
            elsif $1.to_i <= 64
              "http://downloads.dlang.org/releases/2013/dmd.2.#{$1}.zip"
            else
              "http://downloads.dlang.org/releases/2014/dmd.2.#{$1}.#{os}.zip"
            end
          # ldc-0.12.1 or ldc-0.15.0-alpha1
          when /^ldc-(\d+\.\d+\.\d+(-.*)?)$/
            "https://github.com/ldc-developers/ldc/releases/download/v#{$1}/ldc2-#{$1}-#{os}-x86_64.tar.xz"
          # gdc-4.8.2 or gdc-4.9.0-alpha1
          when /^gdc-(\d+\.\d+\.\d+(-.*)?)$/
            case os
            when 'linux'
              host_triplet = 'x86_64-linux-gnu'
            when 'osx'
              host_triplet = 'x86_64-apple-darwin'
            else
              raise "GDC is currently not supported on #{os}."
            end
            "http://gdcproject.org/downloads/binaries/#{host_triplet}/gdc-#{$1}.tar.xz"
          end
        end

        def compiler_cmd
          case config[:d]
            when /^ldc/
              'ldc2'
            when /^gdc/
              'gdc'
            else
              'dmd'
          end
        end

        def dmd_cmd
          case config[:d]
            when /^ldc/
              'ldmd2'
            when /^gdc/
              'gdmd'
            else
              'dmd'
          end
        end
      end
    end
  end
end
