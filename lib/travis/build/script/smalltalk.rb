module Travis
  module Build
    class Script
      class Smalltalk < Script
        DEFAULTS = {}

        def setup
          super
          sh.cmd 'sudo apt-get install --no-install-recommends libc6:i386 ' +
                   'libuuid1:i386', retry: true
          sh.if '-z "$SMALLTALK"' do
            sh.export 'SMALLTALK', 'Squeak5.0'
          end
          sh.cmd "export PROJECT_HOME=\"$(pwd)\""
          sh.cmd "cd $HOME"
          sh.cmd "wget -q -O filetreeCI.zip https://github.com/hpi-swa/filetreeCI/archive/master.zip"
          sh.cmd "unzip -q -o filetreeCI.zip"
          sh.cmd "cd filetreeCI-*"
          sh.cmd "export FILETREE_CI_HOME=\"$(pwd)\""
          sh.cmd "$FILETREE_CI_HOME/run.sh"
        end

      end
    end
  end
end
