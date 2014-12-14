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
            '/new?labels=dart', ansi: :green
          sh.echo 'and mention \`@a14n\` in the issue', ansi: :green

          sh.echo 'Installing Dart', ansi: :yellow
          sh.cmd "sudo apt-get update"
          sh.cmd "sudo apt-get install -y apt-transport-https curl"
          sh.cmd "sudo sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'"
          sh.cmd "sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'"
          sh.cmd "sudo sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_unstable.list > /etc/apt/sources.list.d/dart_unstable.list'"
          sh.cmd "sudo apt-get update"
          case config[:dart]
          when 'stable'
            sh.cmd "sudo apt-get install -y dart/stable"
          when 'dev'
            sh.cmd "sudo apt-get install -y dart/unstable"
          when 'unstable'
            sh.cmd "sudo apt-get install -y dart/unstable"
          else
            sh.cmd "sudo apt-get install -y dart=#{config[:dart]}"
          end
          sh.cmd 'export DART_SDK="/usr/lib/dart/"'
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
          sh.if '-f test/all_test.dart' do
            sh.cmd 'dart test/all_test.dart'
          end
        end
      end
    end
  end
end
