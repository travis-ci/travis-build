module Travis
  module Build
    class Script
      module Git
        DEFAULTS = {
          git: { depth: 100, submodules: true }
        }

        def checkout
          install_source_key
          clone
          ch_dir
          fetch_ref if fetch_ref?
          git_checkout
          submodules if submodules?
          rm_key
          sh.to_s
        end

        private

          def install_source_key
            return unless config[:source_key]

            echo "\nInstalling an SSH key\n"
            cmd "echo '#{config[:source_key]}' | base64 -d > ~/.ssh/id_rsa", echo: false, log: false
            cmd 'chmod 600 ~/.ssh/id_rsa',                echo: false, log: false
            cmd 'eval `ssh-agent` > /dev/null 2>&1',      echo: false, log: false
            cmd 'ssh-add ~/.ssh/id_rsa > /dev/null 2>&1', echo: false, log: false

            # BatchMode - If set to 'yes', passphrase/password querying will be disabled.
            # TODO ... how to solve StrictHostKeyChecking correctly? deploy a knownhosts file?
            cmd 'echo -e "Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config', echo: false, log: false
          end

          def clone
            set 'GIT_ASKPASS', 'echo', :echo => false # this makes git interactive auth fail
            cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, timeout: :git_clone
          end

          def ch_dir
            cmd "cd #{dir}", timeout: false
          end

          def rm_key
            raw 'rm -f ~/.ssh/source_rsa'
          end

          def fetch_ref?
            !!data.ref
          end

          def fetch_ref
            cmd "git fetch origin +#{data.ref}: ", assert: true, timeout: :git_fetch_ref
          end

          def git_checkout
            cmd "git checkout -qf #{data.pull_request ? 'FETCH_HEAD' : data.commit}", assert: true
          end

          def submodules?
            config[:git][:submodules]
          end

          def submodules
            self.if '-f .gitmodules' do
              cmd 'echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config', echo: false
              cmd 'git submodule init'
              cmd 'git submodule update', assert: true, timeout: :git_submodules
            end
          end

          def clone_args
            args = "--depth=#{config[:git][:depth]} --quiet"
            args << " --branch=#{data.branch}" unless data.ref
            args
          end

          def dir
            data.slug
          end
      end
    end
  end
end
