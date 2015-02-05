module Travis
  module Build
    class Script
      class Dart < Script
        DEFAULTS = {
          :dart => 'stable'
        }

        def configure
          super

          sh.fold 'Content Shell dependencies install' do
            sh.echo 'Installing Content Shell dependencies', ansi: :yellow

            # Enable Multiverse Packages:
            sh.cmd "sudo sh -c 'echo \"deb http://gce_debian_mirror.storage.googleapis.com precise contrib non-free\" >> /etc/apt/sources.list'"
            sh.cmd "sudo sh -c 'echo \"deb http://gce_debian_mirror.storage.googleapis.com precise-updates contrib non-free\" >> /etc/apt/sources.list'"
            sh.cmd "sudo sh -c 'apt-get update'"

            # Pre-accepts MSFT Fonts EULA:
            sh.cmd "sudo sh -c 'echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections'"

            # Install all dependencies:
            sh.cmd "sudo sh -c 'apt-get install --no-install-recommends -y -q chromium-browser libudev0 ttf-kochi-gothic ttf-kochi-mincho ttf-mscorefonts-installer ttf-indic-fonts ttf-dejavu-core ttf-indic-fonts-core fonts-thai-tlwg msttcorefonts xvfb'"
          end
        end

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

          sh.fold 'Dart install' do
            sh.echo 'Installing Dart', ansi: :yellow
            sh.cmd "curl #{archive_url}/sdk/dartsdk-linux-x64-release.zip > dartsdk.zip"
            sh.cmd "unzip dartsdk.zip > /dev/null"
            sh.cmd "rm dartsdk.zip"
            sh.cmd 'export DART_SDK="${PWD%/}/dart-sdk"'
            sh.cmd 'export PATH="$DART_SDK/bin:$PATH"'
          end

          sh.fold 'Content Shell install' do
            sh.echo 'Installing Content Shell', ansi: :yellow

            # Download and install Content Shell
            sh.cmd "mkdir content_shell"
            sh.cmd "cd content_shell"
            sh.cmd "curl #{archive_url}/dartium/content_shell-linux-x64-release.zip > content_shell.zip"
            sh.cmd "unzip content_shell.zip > /dev/null"
            sh.cmd "rm content_shell.zip"
            sh.cmd 'export PATH="${PWD%/}/$(ls):$PATH"'
            sh.cmd "cd -"
          end

          sh.fold 'Test Runner install' do
            sh.echo 'Installing Test Runner', ansi: :yellow
            sh.cmd "pub global activate test_runner"
          end
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
          sh.cmd "xvfb-run -s '-screen 0 1024x768x24' pub global run test_runner --disable-ansi"
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
