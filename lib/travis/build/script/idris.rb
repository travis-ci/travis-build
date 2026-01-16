# Community maintainers:
#
#   Aaron Weiss
#   awe@pdgn.co
#   https://github.com/aatxe
#
#   David Christiansen
#   david@davidchristiansen.dk
#   https://github.com/david-christiansen
#
#   Jacob Mitchell
#   jake@requisitebits.com
#   https://github.com/jmitchell
module Travis
  module Build
    class Script
      class Idris < Script
        DEFAULTS = {
          idris: "1.0",
        }

        def idris_package
          "idris-#{config[:idris]}"
        end

        def stack_url
          case config[:os]
          when 'linux'
            os = 'linux-x86_64'
          when 'osx'
            os = 'osx-x86_64'
          end
          "https://www.stackage.org/stack/#{os}"
        end

        def export
          super

          sh.export 'TRAVIS_IDRIS_VERSION', config[:idris].to_s.shellescape,
            echo: false
        end

        def use_directory_cache?
          super || data.cache?(:stack) || data.cache?(:idris)
        end

        # This is pretty much required in order to avoid 45 minute install times.
        def setup_cache
          return unless use_directory_cache?
          super

          if data.cache?(:stack) || data.cache?(:idris)
            sh.fold 'cache.stack' do
              sh.echo ''
              directory_cache.add("$HOME/.stack")
            end
          end
        end

        def setup
          super

          sh.echo 'Idris for Travis-CI is not officially supported, ' \
                  'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
                  ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues' \
                  '/new?labels=idris', ansi: :green
          sh.echo 'and mention \`@aatxe\`, \`@david-christiansen\`' \
                  ' and \`@jmitchell\` in the issue', ansi: :green

          sh.fold 'stack-install' do
            sh.cmd 'CURL_USER_AGENT="Travis-CI $(curl --version | head -n 1)"'

            sh.echo 'Installing Stack', ansi: :yellow
            sh.cmd 'mkdir -p ~/.local/bin'
            sh.cmd 'export PATH=$HOME/.local/bin:$PATH'
            sh.cmd %Q{"curl -A "$CURL_USER_AGENT" -s --retry 7 -L '#{stack_url}'"} \
                     "| tar xz --wildcards --strip-components=1 -C ~/.local/bin '*/stack'"
          end

          sh.fold 'idris-install' do
            sh.echo 'Installing Idris', ansi: :yellow
            sh.cmd %Q{'travis_wait 60 stack install --install-ghc #{idris_package}'}
          end

          def announce
            super

            sh.cmd "idris --version"
            sh.echo ''
          end

          def script
            sh.echo 'Executing the default test script', ansi: :green
            sh.if "-f *.ipkg" do
              sh.cmd "idris --build *.ipkg"
            end
            sh.else do
              sh.echo 'No ipkg files found, so the default test script is empty.', ansi: :yellow
            end
          end
        end
      end
    end
  end
end
