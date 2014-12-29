module Travis
  module Build
    class Script
      class Dart < Script
        DEFAULTS = {
          :dart => 'stable'
        }

        def export
          super

          sh.export 'TRAVIS_DART_VERSION', config[:dart], echo: false
        end

        def setup
          super

          sh.echo 'Dart for Travis-CI is not officially supported, ' \
            'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
            ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues' \
            '/new?labels=community:dart', ansi: :green
          sh.echo 'and mention \`@a14n\`, \`@devoncarew\` and \`@sethladd\`' \
            ' in the issue', ansi: :green

          sh.echo 'Installing Dart', ansi: :yellow
          sh.cmd "curl #{archive_url}/sdk/dartsdk-linux-x64-release.zip > dartsdk.zip"
          sh.cmd "unzip dartsdk.zip > /dev/null"
          sh.cmd "rm dartsdk.zip"
          sh.cmd 'export DART_SDK="${PWD%/}/dart-sdk"'
          sh.cmd 'export PATH="$DART_SDK/bin:$PATH"'

          sh.echo 'Installing Test Runner', ansi: :yellow
          sh.cmd "pub global activate test_runner"
        end

        def announce
          super

          sh.cmd 'dart --version'
          sh.echo ''
        end

        def install
          sh.if '-f pubspec.yaml' do
            sh.cmd "pub get"
          end
        end

        def script
          sh.cmd 'pub global run test_runner --skip-browser-tests'
        end

        private

          def archive_url
            if not ["stable", "dev"].include?(config[:dart])
              sh.failure "Only 'stable' and 'dev' can be used as dart version for now"
            end
            "http://storage.googleapis.com/dart-archive/channels/#{config[:dart]}/release/latest"
          end
      end
    end
  end
end
