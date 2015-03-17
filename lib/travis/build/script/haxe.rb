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

          sh.echo 'Installing Neko', ansi: :yellow
          sh.cmd 'mkdir -p ~/neko'
          sh.cmd %Q{curl -s -L --retry 3 '#{neko_url}' } \
                 '| tar -C ~/neko -x --strip-components=1 -f -'
          sh.cmd 'export PATH="${PATH}:${HOME}/neko"'

          sh.echo 'Installing Haxe', ansi: :yellow
          sh.cmd 'mkdir -p ~/haxe'
          sh.cmd %Q{curl -s -L --retry 3 '#{haxe_url}' } \
                 '| tar -C ~/haxe -x --strip-components=1 -f -'
          sh.cmd 'export PATH="${PATH}:${HOME}/haxe"'
          sh.cmd 'mkdir -p ~/haxe/lib'
          sh.cmd 'haxelib setup ~/haxe/lib'
        end

        def announce
          super

          sh.cmd "haxe -version"
          sh.cmd "neko -version"
        end

        def install
          Dir["*.hxml"].each{|hxml| sh.cmd "yes | haxelib install '#{hxml}'", retry: true}
        end

        def script
          Dir["*.hxml"].each{|hxml| sh.cmd "haxe '#{hxml}'"}
        end

        private

          def neko_url
            case config[:os]
            when 'linux'
              os = 'linux'
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
                'linux32'
              when 'osx'
                'mac'
              end
              "http://hxbuilds.s3-website-us-east-1.amazonaws.com/builds/haxe/#{os}/haxe_latest.tar.gz"
            else
              os = case config[:os]
              when 'linux'
                'linux32'
              when 'osx'
                'osx'
              end
              version = config[:haxe]
              "http://haxe.org/website-content/downloads/#{version.gsub('.',',')}/downloads/haxe-#{version}-#{os}.tar.gz"
            end
          end

      end
    end
  end
end
