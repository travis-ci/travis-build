# Copyright (c) 2015-2016 Software Architecture Group (Hasso Plattner Institute)
# Copyright (c) 2015-2016 Fabio Niephaus, Google Inc.

module Travis
  module Build
    class Script
      class Smalltalk < Script
        DEFAULTS = {}
        HOSTS_FILE = '/etc/hosts'
        TEMP_HOSTS_FILE = '/tmp/hosts'
        SYSCTL_FILE = '/etc/sysctl.conf'
        TEMP_SYSCTL_FILE = '/tmp/sysctl.conf'

        def configure
          super

          if is_squeak? or is_pharo?
            case config[:os]
            when 'linux'
              install_dependencies
            when 'osx'
              # pass
            end

          elsif is_gemstone?

            sh.fold 'gemstone_prepare_dependencies' do
              sh.echo 'Preparing build for GemStone', ansi: :yellow
              gemstone_configure_hosts

              case config[:os]
              when 'linux'
                gemstone_prepare_linux_shared_memory
                gemstone_prepare_linux_dependencies
              when 'osx'
                gemstone_prepare_osx_shared_memory
              end

              gemstone_prepare_netldi
              gemstone_prepare_directories
            end

          end
        end

        def export
          super

          sh.export 'TRAVIS_SMALLTALK_VERSION', smalltalk_version, echo: false
        end

        def setup
          super

          sh.echo 'Smalltalk for Travis-CI is not officially supported, ' \
            'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link', ansi: :green
          sh.echo '  https://github.com/hpi-swa/smalltalkCI/issues', ansi: :green

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

        private

          def smalltalk_version
            config[:smalltalk].to_s
          end

          def is_squeak?
            is_platform?('squeak')
          end

          def is_pharo?
            is_platform?('pharo')
          end

          def is_gemstone?
            is_platform?('gemstone')
          end

          def is_platform?(name)
            config[:smalltalk].to_s.downcase.start_with?(name)
          end

          def install_dependencies
            sh.fold 'install_packages' do
              sh.echo 'Installing dependencies', ansi: :yellow

              sh.cmd 'sudo dpkg --add-architecture i386'
              sh.cmd 'sudo apt-get update -qq', retry: true
              sh.cmd 'sudo apt-get install --no-install-recommends ' +
                     'libc6:i386 libuuid1:i386 libfreetype6:i386 libssl1.0.0:i386', retry: true
            end
          end

          def gemstone_configure_hosts()
            sh.echo 'Configuring /etc/hosts file', ansi: :yellow

            case config[:os]
            when 'linux'
              sh.cmd "sed -e \"s/^\\(127\\.0\\.0\\.1.*\\)$/\\1 $(hostname)/\" #{HOSTS_FILE} | sed -e \"s/^\\(::1.*\\)$/\\1 $(hostname)/\" > #{TEMP_HOSTS_FILE}"
            when 'osx'
              sh.cmd "sed -e \"s/^\\(127\\.0\\.0\\.1.*\\)$/\\1 $(scutil --get HostName)/\" #{HOSTS_FILE} | sed -e \"s/^\\(::1.*\\)$/\\1 $(scutil --get HostName)/\" > #{TEMP_HOSTS_FILE}"
            end
            sh.cmd "cat #{TEMP_HOSTS_FILE} | sudo tee #{HOSTS_FILE} > /dev/null"
          end

          def gemstone_prepare_linux_shared_memory
            sh.echo 'Setting up shared memory', ansi: :yellow

            sh.cmd 'SMALLTALK_CI_TOTALMEM=$(($(awk \'/MemTotal:/{print($2);}\' /proc/meminfo) * 1024))'
            sh.cmd 'SMALLTALK_CI_SHMMAX=$(cat /proc/sys/kernel/shmmax)'
            sh.cmd 'SMALLTALK_CI_SHMALL=$(cat /proc/sys/kernel/shmall)'

            sh.cmd 'SMALLTALK_CI_SHMMAX_NEW=$(($SMALLTALK_CI_TOTALMEM * 3/4))'
            sh.if '$SMALLTALK_CI_SHMMAX_NEW -gt 2147483648' do
              sh.cmd 'SMALLTALK_CI_SHMMAX_NEW=2147483648'
            end

            sh.if '$SMALLTALK_CI_SHMMAX_NEW -gt $SMALLTALK_CI_SHMMAX' do
              sh.cmd 'sudo bash -c "echo $SMALLTALK_CI_SHMMAX_NEW > /proc/sys/kernel/shmmax"'
              sh.cmd "sudo /bin/su -c \"echo 'kernel.shmmax=$SMALLTALK_CI_SHMMAX_NEW' >> #{SYSCTL_FILE}\""
            end

            sh.cmd 'SMALLTALK_CI_SHMALL_NEW=$(($SMALLTALK_CI_SHMALL / 4096))'
            sh.if '$SMALLTALK_CI_SHMALL_NEW -lt $SMALLTALK_CI_SHMALL' do
              sh.cmd 'SMALLTALK_CI_SHMALL_NEW=$SMALLTALK_CI_SHMALL'
            end

            sh.if '$SMALLTALK_CI_SHMALL_NEW -gt $SMALLTALK_CI_SHMALL' do
              sh.cmd 'sudo bash -c "echo $SMALLTALK_CI_SHMALL_NEW > /proc/sys/kernel/shmall"'
            end

            sh.if "! -f #{SYSCTL_FILE} || $(grep -sc \"kern.*m\" #{SYSCTL_FILE}) -eq 0" do
              sh.cmd "echo \"kernelmmax=$(cat /proc/sys/kernel/shmmax)\" >> #{TEMP_SYSCTL_FILE}"
              sh.cmd "echo \"kernelmall=$(cat /proc/sys/kernel/shmall)\" >> #{TEMP_SYSCTL_FILE}"
              sh.cmd "sudo bash -c \"cat #{TEMP_SYSCTL_FILE} >> #{SYSCTL_FILE}\""
              sh.cmd "/bin/rm -f #{TEMP_SYSCTL_FILE}"
            end
          end

          def gemstone_prepare_osx_shared_memory
            sh.echo 'Setting up shared memory', ansi: :yellow

            sh.cmd 'SMALLTALK_CI_TOTALMEM=$(($(sysctl hw.memsize | cut -f2 -d\' \') * 1024))'
            sh.cmd 'SMALLTALK_CI_SHMMAX=$(sysctl kern.sysv.shmmax | cut -f2 -d\' \')'
            sh.cmd 'SMALLTALK_CI_SHMALL=$(sysctl kern.sysv.shmall | cut -f2 -d\' \')'

            sh.cmd 'SMALLTALK_CI_SHMMAX_NEW=$(($SMALLTALK_CI_TOTALMEM * 3/4))'
            sh.if '$SMALLTALK_CI_SHMMAX_NEW -gt 2147483648' do
              sh.cmd 'SMALLTALK_CI_SHMMAX_NEW=2147483648'
            end

            sh.if '$SMALLTALK_CI_SHMMAX_NEW -gt $SMALLTALK_CI_SHMMAX' do
              sh.cmd 'sudo sysctl -w kern.sysv.shmmax=$SMALLTALK_CI_SHMMAX_NEW'
            end

            sh.cmd 'SMALLTALK_CI_SHMALL_NEW=$(($SMALLTALK_CI_SHMALL / 4096))'
            sh.if '$SMALLTALK_CI_SHMALL_NEW -lt $SMALLTALK_CI_SHMALL' do
              sh.cmd 'SMALLTALK_CI_SHMALL_NEW=$SMALLTALK_CI_SHMALL'
            end

            sh.if '$SMALLTALK_CI_SHMALL_NEW -gt $SMALLTALK_CI_SHMALL' do
              sh.cmd 'sudo sysctl -w kern.sysv.shmall=$SMALLTALK_CI_SHMALL_NEW'
            end

            sh.if "! -f #{SYSCTL_FILE} || $(grep -sc \"kern.*m\" #{SYSCTL_FILE}) -eq 0" do
              sh.cmd "sysctl kern.sysv.shmmax kern.sysv.shmall kern.sysv.shmmin kern.sysv.shmmni | tr \":\" \"=\" | tr -d \" \" >> #{TEMP_SYSCTL_FILE}"
              sh.cmd "sudo bash -c \"cat #{TEMP_SYSCTL_FILE} >> #{SYSCTL_FILE}\""
              sh.cmd "/bin/rm -f #{TEMP_SYSCTL_FILE}"
            end
          end

          def gemstone_prepare_linux_dependencies
            sh.if '$(lsb_release -cs) = precise' do
              gemstone_install_linux_dependencies
              sh.cmd 'sudo ln -f -s /lib/i386-linux-gnu/libpam.so.0 /lib/libpam.so.0'
              sh.cmd 'sudo ln -f -s /usr/lib/i386-lin-gnu/libstdc++.so.6 /usr/lib/i386-linux-gnu/libstdc++.so'
            end
            sh.if '$(lsb_release -cs) = trusty' do
              gemstone_install_linux_dependencies
              sh.cmd 'sudo ln -f -s /usr/lib/i386-lin-gnu/libstdc++.so.6 /usr/lib/i386-linux-gnu/libstdc++.so'
            end
          end

          def gemstone_install_linux_dependencies
            sh.fold 'gemstone_dependencies' do
              sh.echo 'Installing GemStone dependencies', ansi: :yellow

              sh.cmd 'sudo dpkg --add-architecture i386'
              sh.cmd 'sudo apt-get update -qq', retry: true
              sh.cmd 'sudo apt-get install --no-install-recommends ' +
                     'libpam0g:i386 libssl1.0.0:i386 gcc-multilib ' +
                     'libstdc++6:i386 libfreetype6:i386 pstack ' +
                     'libgl1-mesa-glx:i386 libxcb-dri2-0:i386', retry: true
              sh.cmd "sudo /bin/su -c \"echo 'kernel.yama.ptrace_scope = 0' >>/etc/sysctl.d/10-ptrace.conf\""
            end
          end

          def gemstone_prepare_netldi
            sh.if '$(grep -sc "^gs64ldi" /etc/services) -eq 0' do
              sh.echo 'Setting up GemStone netldi service port', ansi: :yellow
              sh.cmd "sudo bash -c 'echo \"gs64ldi         50377/tcp        # Gemstone netldi\"  >> /etc/services'"
            end
          end

          def gemstone_prepare_directories
            sh.if '! -e /opt/gemstone' do
              sh.echo 'Creating /opt/gemstone directory', ansi: :yellow

              sh.cmd 'sudo mkdir -p /opt/gemstone /opt/gemstone/log /opt/gemstone/locks'
              sh.cmd 'sudo chown $USER:${GROUPS[0]} /opt/gemstone /opt/gemstone/log /opt/gemstone/locks'
              sh.cmd 'sudo chmod 770 /opt/gemstone /opt/gemstone/log /opt/gemstone/locks'
            end
          end

      end
    end
  end
end
