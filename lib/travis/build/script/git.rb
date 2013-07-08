require 'shellwords'

module Travis
  module Build
    class Script
      module Git
        DEFAULTS = {
          git: { depth: 50, submodules: true, stategy: 'clone' }
        }

        def checkout
          install_source_key
          if tarball_clone?
            download_tarball
          else
            git_clone
            ch_dir
            fetch_ref if fetch_ref?
            git_checkout
            submodules if submodules?
          end
          rm_key
          sh.to_s
        end

        private

          def install_source_key
            return unless config[:source_key]

            echo "\nInstalling an SSH key\n"
            cmd "echo '#{config[:source_key]}' | base64 --decode > ~/.ssh/id_rsa", echo: false, log: false
            cmd 'chmod 600 ~/.ssh/id_rsa',                echo: false, log: false
            cmd 'eval `ssh-agent` > /dev/null 2>&1',      echo: false, log: false
            cmd 'ssh-add ~/.ssh/id_rsa > /dev/null 2>&1', echo: false, log: false

            # BatchMode - If set to 'yes', passphrase/password querying will be disabled.
            # TODO ... how to solve StrictHostKeyChecking correctly? deploy a knownhosts file?
            cmd 'echo -e "Host github.com\n\tBatchMode yes\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config', echo: false, log: false
          end

          def download_tarball
            cmd "mkdir -p #{dir}", assert: true
            cmd "curl -o #{sanitized_slug}.tar.gz -L #{tarball_url}", assert: true, retry: true, fold: "tarball.#{next_git_fold_number}"
            cmd "tar xfz #{sanitized_slug}.tar.gz", assert: true
            cmd "mv #{sanitized_slug}-#{data.commit[0..6]}/* #{dir}", assert: true
            ch_dir
          end

          def git_clone
            set 'GIT_ASKPASS', 'echo', :echo => false # this makes git interactive auth fail
            cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, timeout: :git_clone, fold: "git.#{next_git_fold_number}", retry: true
          end

          def ch_dir
            cmd "cd #{dir}", assert: true, timeout: false
          end

          def rm_key
            raw 'rm -f ~/.ssh/source_rsa'
          end

          def fetch_ref?
            !!data.ref
          end

          def fetch_ref
            cmd "git fetch origin +#{data.ref}: ", assert: true, timeout: :git_fetch_ref, fold: "git.#{next_git_fold_number}"
          end

          def git_checkout
            cmd "git checkout -qf #{data.pull_request ? 'FETCH_HEAD' : data.commit}", assert: true, fold: "git.#{next_git_fold_number}"
          end

          def submodules?
            config[:git][:submodules]
          end

          def submodules
            self.if '-f .gitmodules' do
              cmd 'echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config', echo: false
              cmd 'git submodule init', fold: "git.#{next_git_fold_number}"
              cmd 'git submodule update', assert: true, timeout: :git_submodules, fold: "git.#{next_git_fold_number}"
            end
          end

          def clone_args
            args = "--depth=#{config[:git][:depth]}"
            args << " --branch=#{data.branch.shellescape}" unless data.ref
            args
          end

          def tarball_clone?
            config[:git][:stategy] == 'tarball'
          end

          def dir
            data.slug
          end

          def tarball_url
            token = data.token ? "?token=#{data.token}" : nil
            "https://api.github.com/repos/#{data.slug}/tarball/#{data.commit}#{token}"
          end

          def sanitized_slug
            data.slug.gsub('/', '-')
          end

          def next_git_fold_number
            @git_fold_number ||= 0
            @git_fold_number  += 1
          end
      end
    end
  end
end
