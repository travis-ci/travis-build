module Travis
  module Build
    class Script
      class Smalltalk < Script
        DEFAULTS = {}

        def configure
          super
          sh.fold 'install_packages' do
            sh.echo 'Installing libc6:i386 and libuuid1:i386', ansi: :yellow
            sh.cmd 'sudo apt-get update -qq', retry: true
            sh.cmd 'sudo apt-get install --no-install-recommends libc6:i386 ' +
                   'libuuid1:i386', retry: true
          end
        end

        def export
          super
          sh.export 'SMALLTALK', config[:smalltalk], echo: false
         end

        def setup
          super
          sh.cmd "export PROJECT_HOME=\"$(pwd)\""
          sh.cmd "pushd $HOME", echo: false
          sh.fold 'download_filetreeci' do
            sh.echo 'Downloading and extracting filetreeCI', ansi: :yellow
            sh.cmd "wget -q -O filetreeCI.zip https://github.com/hpi-swa/filetreeCI/archive/master.zip"
            sh.cmd "unzip -q -o filetreeCI.zip"
            sh.cmd "pushd filetreeCI-*", echo: false
            sh.cmd "export FILETREE_CI_HOME=\"$(pwd)\""
            sh.cmd "popd; popd", echo: false
          end
          sh.cmd "$FILETREE_CI_HOME/run.sh"
        end

      end
    end
  end
end
