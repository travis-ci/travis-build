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
          haxe: '3.2.1',
          neko: '2.1.0'
        }

        def export
          super

          sh.export 'TRAVIS_HAXE_VERSION', config[:haxe].to_s, echo: false
          sh.export 'TRAVIS_NEKO_VERSION', config[:neko].to_s, echo: false
        end

        def configure
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
            neko_path = '${HOME}/neko'

            sh.echo 'Installing Neko', ansi: :yellow

            # Install dependencies
            case config[:os]
            when 'linux'
              sh.cmd 'sudo apt-get update -qq', retry: true
              sh.cmd 'sudo apt-get install libgc1c2 -qq', retry: true # required by neko
            when 'osx'
              # pass
            end

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

            case config[:os]
            when 'linux'
              sh.cmd 'sudo ldconfig'
            when 'osx'
              # pass
            end
          end

          sh.fold('haxe-install') do
            haxe_path = '${HOME}/haxe'

            sh.echo 'Installing Haxe', ansi: :yellow
            sh.cmd %Q{mkdir -p #{haxe_path}}
            sh.cmd %Q{curl -s -L --retry 3 '#{haxe_url}' | tar -C #{haxe_path} -x -z --strip-components=1 -f -}, assert: true, echo: true, timing: true

            ['haxe', 'haxelib'].each do |bin|
              sh.cmd %Q{sudo ln -s "#{haxe_path}/#{bin}" /usr/local/bin/}
            end
            sh.cmd %Q{sudo mkdir -p /usr/local/lib/haxe/}
            sh.cmd %Q{sudo ln -s "#{haxe_path}/std" /usr/local/lib/haxe/std}

            sh.cmd %Q{export HAXE_STD_PATH="#{haxe_path}/std"}
            sh.cmd %Q{mkdir -p #{haxe_path}/lib}
            sh.cmd %Q{haxelib setup #{haxe_path}/lib}
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

          def neko_url
            case config[:os]
            when 'linux'
              os = 'linux64'
            when 'osx'
              os = 'osx64'
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
              "http://haxe.org/website-content/downloads/#{version}/downloads/haxe-#{version}-#{os}.tar.gz"
            end
          end

      end
    end
  end
end
