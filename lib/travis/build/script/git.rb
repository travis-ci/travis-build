require 'shellwords'

module Travis
  module Build
    class Script
      module Git
        DEFAULTS = {
          git: { depth: 50, submodules: true, strategy: 'clone' }
        }

        def checkout
          install_ssh_key
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

          def decode_cmd
            data.ssh_key.encoded? ? ' | base64 --decode ' : ''
          end

          def install_ssh_key
            return unless data.ssh_key

            source = data.ssh_key.source.gsub(/[_-]+/, ' ')
            echo "\nInstalling an SSH key from #{source}\n"
            cmd "echo #{data.ssh_key.value.shellescape} #{decode_cmd} > ~/.ssh/id_rsa", echo: false, log: false
            cmd 'chmod 600 ~/.ssh/id_rsa',                echo: false, log: false
            cmd 'eval `ssh-agent` &> /dev/null',      echo: false, log: false
            cmd 'ssh-add ~/.ssh/id_rsa &> /dev/null', echo: false, log: false

            # BatchMode - If set to 'yes', passphrase/password querying will be disabled.
            # TODO ... how to solve StrictHostKeyChecking correctly? deploy a knownhosts file?
            cmd %(echo -e "Host #{data.source_host}\n\tBatchMode yes\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config), echo: false, log: false
          end

          def download_tarball
            cmd "mkdir -p #{dir}", assert: true
            curl_cmd = "curl -o #{sanitized_slug}.tar.gz #{oauth_token}-L #{tarball_url}"
            cmd curl_cmd, echo: curl_cmd.gsub(data.token || /\Za/, '[SECURE]'), assert: true, retry: true, fold: "tarball.#{next_git_fold_number}"
            cmd "tar xfz #{sanitized_slug}.tar.gz", assert: true
            cmd "mv #{sanitized_slug}-#{data.commit[0..6]}/* #{dir}", assert: true
            ch_dir
          end

          def git_clone
            set 'GIT_ASKPASS', 'echo', :echo => false # this makes git interactive auth fail
            self.if "! -d #{dir}/.git" do
              cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, fold: "git.#{next_git_fold_number}", retry: true
            end
            self.else do
              cmd "git fetch origin", assert: true, fold: "git.#{next_git_fold_number}", retry: true
            end
          end

          def ch_dir
            cmd "cd #{dir}", assert: true
          end

          def rm_key
            raw 'rm -f ~/.ssh/source_rsa'
          end

          def fetch_ref?
            !!data.ref
          end

          def fetch_ref
            cmd "git fetch origin +#{data.ref}: ", assert: true, fold: "git.#{next_git_fold_number}", retry: true
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
              cmd 'git submodule update', assert: true, fold: "git.#{next_git_fold_number}", retry: true
            end
          end

          def clone_args
            args = "--depth=#{config[:git][:depth].to_s.shellescape}"
            args << " --branch=#{data.branch.shellescape}" unless data.ref
            args
          end

          def tarball_clone?
            config[:git][:strategy] == 'tarball'
          end

          def dir
            data.slug
          end

          def tarball_url
            "#{data.api_url}/tarball/#{data.commit}"
          end

          def oauth_token
            data.token ? "-H \"Authorization: token #{data.token}\" " : nil
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
