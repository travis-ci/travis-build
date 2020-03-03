# Community maintainers:
#
#   Andy Li
#   andy@onthewings.net
#   https://github.com/andyli
#
#   Cauê Waneck
#   waneck@gmail.com
#   https://github.com/waneck
#
#   Simon Krajewski
#   simon@haxe.org
#   https://github.com/Simn
#
module Travis
  module Build
    class Script
      class Haxe < Script

        DEFAULTS = {
          haxe: 'stable',
          neko: '2.3.0'
        }

        def export
          super

          sh.export 'TRAVIS_HAXE_VERSION', haxe_version, echo: false
          sh.export 'TRAVIS_NEKO_VERSION', config[:neko].to_s, echo: false
        end

        def configure
          super

          sh.echo 'Haxe for Travis-CI is not officially supported, ' \
                  'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
                  ansi: :green
          sh.echo '  https://travis-ci.community/c/languages/haxe', ansi: :green
          sh.echo 'and mention \`@andyli\`, \`@waneck\`, and \`@Simn\`'\
                  ' in the issue', ansi: :green

          sh.fold('neko-install') do
            sh.echo 'Installing Neko', ansi: :yellow

            # Install dependencies
            case config[:os]
            when 'linux'
              sh.cmd 'travis_apt_get_update', retry: true, echo: true, timing: true
              sh.cmd 'sudo apt-get install libgc1c2 -qq', retry: true, echo: true, timing: true # required by neko
            when 'windows'
              # pass
            when 'osx'
              # pass
            end

            case config[:os]
            when 'linux', 'osx'
              neko_path = '${TRAVIS_HOME}/neko'
              sh.cmd %Q{mkdir -p #{neko_path}}
              sh.cmd %Q{curl -s -L --retry 3 '#{neko_url}' | tar -C #{neko_path} -x -z --strip-components=1 -f -}, assert: true, echo: true, timing: true
              # NEKOPATH is required by `nekotools boot ...`
              sh.cmd %Q{export NEKOPATH="#{neko_path}"}

              ['neko', 'nekoc', 'nekoml', 'nekotools'].each do |bin|
                sh.cmd %Q{sudo ln -s "#{neko_path}/#{bin}" /usr/local/bin/}
              end
              sh.cmd %Q{for lib in #{neko_path}/libneko.*; do sudo ln -s "$lib" /usr/local/lib/; done}
              sh.cmd %Q{for header in #{neko_path}/include/*; do sudo ln -s "$header" /usr/local/include/; done}
              sh.cmd %Q{sudo mkdir -p /usr/local/lib/neko/}
              sh.cmd %Q{for ndll in #{neko_path}/*.ndll; do sudo ln -s "$ndll" /usr/local/lib/neko/; done}
              sh.cmd %Q{sudo ln -s "#{neko_path}/nekoml.std" /usr/local/lib/neko/}
            when 'windows'
              neko_path = '/c/neko'
              sh.cmd %Q{curl -s -L --retry 3 '#{neko_url}' -o neko.zip}, assert: true, echo: true, timing: true
              sh.cmd %Q{unzip -q neko.zip}, assert: true, echo: true, timing: true
              sh.cmd %Q{rm neko.zip}, assert: true, echo: true, timing: true
              sh.cmd %Q{mv neko-*-win* #{neko_path}}, assert: true, echo: true, timing: true

              # NEKOPATH is required by `nekotools boot ...`
              sh.cmd %Q{export NEKOPATH="#{neko_path}"}
              sh.cmd %Q{export "PATH=#{neko_path}:$PATH"}
            end

            case config[:os]
            when 'linux'
              sh.cmd 'sudo ldconfig'
            when 'osx', 'windows'
              # pass
            end
          end

          sh.fold('haxe-install') do
            sh.echo 'Installing Haxe', ansi: :yellow

            case config[:os]
            when 'linux', 'osx'
              haxe_path = '${TRAVIS_HOME}/haxe'
              sh.cmd %Q{mkdir -p #{haxe_path}}
              sh.cmd %Q{curl -s -L --retry 3 '#{haxe_url}' | tar -C #{haxe_path} -x -z --strip-components=1 -f -}, assert: true, echo: true, timing: true

              ['haxe', 'haxelib'].each do |bin|
                sh.cmd %Q{sudo ln -s "#{haxe_path}/#{bin}" /usr/local/bin/}
              end
              sh.cmd %Q{sudo mkdir -p /usr/local/lib/haxe/}
              sh.cmd %Q{sudo ln -s "#{haxe_path}/std" /usr/local/lib/haxe/std}

              sh.cmd %Q{export HAXE_STD_PATH="#{haxe_path}/std"}
              sh.cmd %Q{mkdir -p #{haxe_path}/lib}
              sh.cmd %Q{haxelib setup #{haxe_path}/lib}, assert: true, echo: true, timing: true
            when 'windows'
              haxe_path = '/c/haxe'
              sh.cmd %Q{curl -s -L --retry 3 '#{haxe_url}' -o haxe.zip}, assert: true, echo: true, timing: true
              sh.cmd %Q{unzip -q haxe.zip}, assert: true, echo: true, timing: true
              sh.cmd %Q{rm haxe.zip}, assert: true, echo: true, timing: true
              sh.cmd %Q{mv haxe* /c/haxe}, assert: true, echo: true, timing: true

              sh.cmd %Q{export HAXE_STD_PATH="/c/haxe/std"}
              sh.cmd %Q{export "PATH=/c/haxe:$PATH"}
              sh.cmd %Q{mkdir -p /c/haxe/lib}
              sh.cmd %Q{haxelib setup /c/haxe/lib}, assert: true, echo: true, timing: true
            end
          end
        end

        def announce
          super

          sh.fold('haxe-version') do
            sh.cmd "haxe -version 2>&1", assert: true, echo: true
          end
          sh.fold('neko-version') do
            sh.cmd "neko -version 2>&1", assert: true, echo: true
          end
        end

        def install
          if config[:hxml]
            config[:hxml].each do |hxml|
              sh.cmd "yes | haxelib install \"#{hxml}\"", retry: true
            end
          end
        end

        def script
          if config[:hxml]
            config[:hxml].each do |hxml|
              sh.cmd "haxe \"#{hxml}\""
            end
          else
            sh.failure 'No "hxml:" and "script:" is specified. Please specify at least one of them in your .travis.yml to run tests.'
          end
        end

        private

          def haxe_stable
            require 'faraday'

            def haxeorg_stable
              versions = JSON.parse(Faraday.get("https://haxe.org/website-content/downloads/versions.json").body.to_s)
              versions['current']
            rescue
              nil
            end

            def github_stable
              versions = JSON.parse(Faraday.get("https://api.github.com/repos/HaxeFoundation/haxe/releases/latest").body.to_s)
              versions['name']
            rescue
              nil
            end

            haxeorg_stable || github_stable || "4.0.2"
          end

          def haxe_version
            case config[:haxe]
            when 'stable'
              haxe_stable
            else
              Array(config[:haxe]).first.to_s
            end
          end

          def neko_url
            haxe_ver = haxe_version
            neko_ver = Array(config[:neko]).first
            file = case config[:os]
            when 'linux'
              "neko-#{neko_ver}-linux64.tar.gz"
            when 'osx'
              "neko-#{neko_ver}-osx64.tar.gz"
            when 'windows'
              if haxe_ver == "development" || haxe_ver.to_i >= 4
                "neko-#{neko_ver}-win64.zip"
              else
                "neko-#{neko_ver}-win.zip"
              end
            end
            "https://github.com/HaxeFoundation/neko/releases/download/v#{neko_ver.to_s.gsub(".", "-")}/#{file}"
          end

          def haxe_url
            haxe_ver = haxe_version
            case haxe_ver
            when 'development'
              file = case config[:os]
              when 'linux'
                "linux64/haxe_latest.tar.gz"
              when 'osx'
                "mac/haxe_latest.tar.gz"
              when 'windows'
                "windows64/haxe_latest.zip"
              end
              "https://build.haxe.org/builds/haxe/#{file}"
            else
              file = case config[:os]
              when 'linux'
                "haxe-#{haxe_ver}-linux64.tar.gz"
              when 'osx'
                "haxe-#{haxe_ver}-osx.tar.gz"
              when 'windows'
                "haxe-#{haxe_ver}-win64.zip"
              end
              "https://haxe.org/website-content/downloads/#{haxe_ver}/downloads/#{file}"
            end
          end

      end
    end
  end
end
