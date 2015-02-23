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
          super << '--d-' << config[:d]
        end

        def export
          super
          sh.export 'DC', compiler_cmd
          sh.export 'DMD', dmd_cmd
        end

        def setup
          super

          sh.echo 'D support for Travis-CI is community maintained.', ansi: :green
          sh.echo 'Please make sure to ping @MartinNowak, @klickverbot and @ibuclaw '\
            'when filing issues under https://github.com/travis-ci/travis-ci/issues.', ansi: :green

          sh.fold 'compiler-download' do
            sh.echo 'Installing compiler and dub', ansi: :yellow

            sh.cmd 'CURL_USER_AGENT="Travis-CI $(curl --version | head -n 1)"'
            sh.cmd 'curl() { command curl -fsSL --retry 3 -A "${CURL_USER_AGENT}" "$@"; }'

            case compiler_cmd
            when 'dmd'
              binpath, libpath = {
                'linux' => ['dmd2/linux/bin64', 'dmd2/linux/lib64'],
                'osx' => ['dmd2/osx/bin', 'dmd2/osx/lib'] }[os]

              sh.cmd "curl #{compiler_url} > ~/dmd.zip"
              sh.cmd 'unzip -q -d ~ ~/dmd.zip'
            when 'ldc2'
              binpath, libpath = 'ldc/bin', 'ldc/lib'

              sh.cmd 'mkdir ${HOME}/ldc', echo: false
              sh.cmd "curl #{compiler_url} | tar --strip-components=1 -C ~/ldc -Jxf -"
            when 'gdc'
              binpath, libpath = 'gdc/bin', 'gdc/lib'

              sh.cmd 'mkdir ${HOME}/gdc', echo: false
              sh.cmd "curl #{compiler_url} | tar --strip-components=1 -C ~/gdc -Jxf -"
              sh.cmd 'curl https://raw.githubusercontent.com/D-Programming-GDC/GDMD/master/dmd-script > '\
                "~/#{binpath}/gdmd && chmod +x ~/#{binpath}/gdmd"
            end

            sh.cmd 'LATEST_DUB=$(curl http://code.dlang.org/download/LATEST)', echo: false
            sh.cmd "curl http://code.dlang.org/files/dub-${LATEST_DUB}-#{os}-x86_64.tar.gz"\
              " | tar -C ~/#{binpath} -xzf -"
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
          sh.cmd 'dub --help | tail -n 1'
        end

        def script
          sh.cmd "dub test --compiler=#{compiler_cmd}"
        end

        private

        def os
          config[:os] || 'linux'
        end

        def compiler_url(compiler = config[:d])
          case compiler
          # dmd-2.062, dmd-2.065.0, dmd-2.066.1-rc3
          when /^dmd-2\.(?<maj>\d{3})(?<min>\.\d)?(?<suffix>-.*)?$/
            basename = "dmd.2.#{$~[:maj]}#{$~[:min]}#{$~[:suffix]}"
            folder = '2.'+$~[:maj]

            # since 2.065
            if $~[:maj].to_i >= 65
              basename += '.'+os # use smaller OS specific zips
              folder += $~[:min] # folder uses .minor
            end

            if $~[:suffix] # pre-release
              "http://downloads.dlang.org/pre-releases/2.x/#{folder}/#{basename}.zip"
            else
              "http://downloads.dlang.org/releases/2.x/#{folder}/#{basename}.zip"
            end

          # ldc-0.12.1 or ldc-0.15.0-alpha1
          when /^ldc-(\d+\.\d+\.\d+(-.*)?)$/
            'https://github.com/ldc-developers/ldc/releases/download'\
              "/v#{$1}/ldc2-#{$1}-#{os}-x86_64.tar.xz"

          # gdc-4.8.2 or gdc-4.9.0-alpha1
          when /^gdc-(\d+\.\d+\.\d+(-.*)?)$/
            case os
            when 'linux'
              host_triplet = 'x86_64-linux-gnu'
            when 'osx'
              host_triplet = 'x86_64-apple-darwin'
            else
              fail "GDC is currently not supported on #{os}."
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
