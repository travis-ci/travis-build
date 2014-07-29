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
            sh.cd dir
            fetch_ref if fetch_ref?
            git_checkout
            submodules if submodules?
          end
          rm_key
        end

        private

          def install_ssh_key
            return unless data.ssh_key

            source = " from: #{data.ssh_key.source.gsub(/[_-]+/, ' ')}" if data.ssh_key.source
            sh.echo "\nInstalling an SSH key#{source}\n"

            sh.file '~/.ssh/id_rsa', data.ssh_key.value, decode: data.ssh_key.encoded?
            sh.chmod 600, '~/.ssh/id_rsa'
            sh.cmd 'eval `ssh-agent` &> /dev/null'
            sh.cmd 'ssh-add ~/.ssh/id_rsa &> /dev/null'

            # BatchMode - If set to 'yes', passphrase/password querying will be disabled.
            # TODO ... how to solve StrictHostKeyChecking correctly? deploy a knownhosts file?
            sh.file "Host #{data.source_host}\n\tBatchMode yes\n\tStrictHostKeyChecking no\n", '~/.ssh/config', append: true
          end

          def download_tarball
            curl = "curl -o #{sanitized_slug}.tar.gz #{oauth_token}-L #{tarball_url}"
            echo = curl.gsub(data.token || /\Za/, '[SECURE]')

            sh.cmd "mkdir -p #{dir}"
            sh.cmd curl, assert: true, echo: echo, retry: true, fold: "tarball.#{next_git_fold_number}"
            sh.cmd "tar xfz #{sanitized_slug}.tar.gz", echo: true, assert: true
            sh.cmd "mv #{sanitized_slug}-#{data.commit[0..6]}/* #{dir}", assert: true
            sh.cd dir
          end

          def git_clone
            sh.export 'GIT_ASKPASS', 'echo' # this makes git interactive auth fail
            sh.if "! -d #{dir}/.git" do
              sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, echo: true, retry: true
            end
            sh.else do
              sh.cmd "git fetch origin", assert: true, echo: true, retry: true
            end
          end

          def rm_key
            sh.rm '~/.ssh/source_rsa', force: true
          end

          def fetch_ref?
            !!data.ref
          end

          def fetch_ref
            sh.cmd "git fetch origin +#{data.ref}:", assert: true, echo: true, fold: "git.#{next_git_fold_number}", retry: true
          end

          def git_checkout
            sh.cmd "git checkout -qf #{data.pull_request ? 'FETCH_HEAD' : data.commit}", assert: true, echo: true, fold: "git.#{next_git_fold_number}"
          end

          def submodules?
            config[:git][:submodules]
          end

          def submodules
            sh.if '-f .gitmodules' do
              sh.fold "git.#{next_git_fold_number}" do
                sh.cmd 'echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config', echo: false
                sh.cmd 'git submodule init', echo: true, assert: true
                sh.cmd 'git submodule update', echo: true, assert: true, retry: true
              end
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
