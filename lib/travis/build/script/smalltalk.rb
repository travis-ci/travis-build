module Travis
  module Build
    class Script
      class Smalltalk < Script
        DEFAULTS = {}

        def configure
          super
          case config[:os]
          when 'linux'
            sh.fold 'install_packages' do
              sh.echo 'Installing dependencies', ansi: :yellow
              sh.cmd 'sudo apt-get update -qq', retry: true
              sh.cmd 'sudo apt-get install --no-install-recommends ' +
                     'libc6:i386 libuuid1:i386 libfreetype6:i386', retry: true
            end
          when 'osx'
            # pass
          end
        end

        def export
          super
          sh.export 'SMALLTALK', config[:smalltalk], echo: false
         end

        def setup
          super

          sh.echo 'Smalltalk for Travis-CI is not officially supported, but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link', ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues/new?labels=community:smalltalk', ansi: :green
          sh.echo 'and mention \`@bahnfahren\`, \`@chistopher\`, \`@fniephaus\`, \`@jchromik\` and \`@Nef10\` in the issue', ansi: :green

          sh.cmd "export PROJECT_HOME=\"$(pwd)\""
          sh.cmd "pushd $HOME > /dev/null", echo: false
          sh.fold 'download_smalltalkci' do
            sh.echo 'Downloading and extracting smalltalkCI', ansi: :yellow
            sh.cmd "wget -q -O smalltalkCI.zip https://github.com/hpi-swa/smalltalkCI/archive/master.zip"
            sh.cmd "unzip -q -o smalltalkCI.zip"
            sh.cmd "pushd smalltalkCI-* > /dev/null", echo: false
            sh.cmd "source env_vars"
            sh.cmd "popd > /dev/null; popd > /dev/null", echo: false
          end
        end

        def script
          super
          sh.cmd "$SMALLTALK_CI_HOME/run.sh"
        end

      end
    end
  end
end
