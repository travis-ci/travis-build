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
          haxe: '3.1.3',
          neko: '2.0.0'
        }

        def configure
          super

          case config[:os]
          when 'linux'
            sh.cmd 'sudo apt-get update -qq'
            sh.cmd 'sudo apt-get install libgc1c2 -qq' # required by neko
          when 'osx'
            # pass
          end
        end

        def export
          super

          sh.export 'TRAVIS_HAXE_VERSION', config[:haxe].to_s, echo: false
          sh.export 'TRAVIS_NEKO_VERSION', config[:neko].to_s, echo: false
        end

        def setup
          super

          sh.echo 'Haxe for Travis-CI is not officially supported, ' \
                  'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
                  ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues' \
                  '/new?labels=haxe', ansi: :green
          sh.echo 'and mention \`@andyli\`, \`@waneck\`, and \`@Simn\`'\
                  ' in the issue', ansi: :green

          sh.fold('neko-install') do
            sh.echo 'Installing Neko', ansi: :yellow
            sh.cmd 'mkdir -p ~/neko'
            sh.cmd %Q{curl -s -L --retry 3 '#{neko_url}' } \
                   '| tar -C ~/neko -x -z --strip-components=1 -f -'
            sh.cmd 'export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOME}/neko"' # for loading libneko.so
            sh.cmd 'export PATH="${PATH}:${HOME}/neko"'
          end

          sh.fold('haxe-install') do
            sh.echo 'Installing Haxe', ansi: :yellow
            sh.cmd 'mkdir -p ~/haxe'
            sh.cmd %Q{curl -s -L --retry 3 '#{haxe_url}' } \
                   '| tar -C ~/haxe -x -z --strip-components=1 -f -'
            sh.cmd 'export PATH="${PATH}:${HOME}/haxe"'
            sh.cmd 'export HAXE_STD_PATH="${HOME}/haxe/std"'
            sh.cmd 'mkdir -p ~/haxe/lib'
            sh.cmd 'haxelib setup ~/haxe/lib'
          end
        end

        def announce
          super

          # Neko 2.0.0 output the version number without linebreak.
          # The webpage has trouble displaying it without wrapping with echo.
          sh.cmd "echo $(haxe -version)"
          sh.cmd "echo $(neko -version)"
        end

        def install
          if config[:hxml]
            config[:hxml].each do |hxml|
              sh.cmd "yes | haxelib install '#{hxml}'", retry: true
            end
          end
        end

        def script
          if config[:hxml]
            config[:hxml].each do |hxml|
              sh.cmd "haxe '#{hxml}'"
            end
          end
        end

        private

          def neko_url
            case config[:os]
            when 'linux'
              os = 'linux64'
            when 'osx'
              os = 'osx'
            end
            version = config[:neko]
            "http://nekovm.org/_media/neko-#{version}-#{os}.tar.gz"
          end

          def haxe_url
            case config[:haxe]
            when 'development'
              os = case config[:os]
              when 'linux'
                'linux64'
              when 'osx'
                'mac'
              end
              "http://hxbuilds.s3-website-us-east-1.amazonaws.com/builds/haxe/#{os}/haxe_latest.tar.gz"
            else
              os = case config[:os]
              when 'linux'
                'linux64'
              when 'osx'
                'osx'
              end
              version = config[:haxe].to_s
              "http://haxe.org/website-content/downloads/#{version.gsub('.',',')}/downloads/haxe-#{version}-#{os}.tar.gz"
            end
          end

      end
    end
  end
end
