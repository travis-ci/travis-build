require 'shellwords'
require 'base64'

module Travis
  module Build
    class Script
      class Git < Struct.new(:sh, :data)
        DEFAULTS = {
          git: { depth: 50, submodules: true, strategy: 'clone' }
        }

        def checkout
          install_ssh_key
          if use_tarball?
            download_tarball
          else
            sh.fold 'git.checkout' do
              git_clone_or_fetch
              sh.cd dir
              fetch_ref if fetch_ref?
              git_checkout
            end
            submodules if submodules?
          end
          rm_key
        end

        private

          def config
            data.config
          end

          def install_ssh_key
            return unless data.ssh_key

            source = " from: #{data.ssh_key.source.gsub(/[_-]+/, ' ')}" if data.ssh_key.source
            sh.echo "\nInstalling an SSH key#{source}"
            sh.echo "Key fingerprint: #{data.ssh_key.fingerprint}\n" if data.ssh_key.fingerprint

            sh.file '~/.ssh/id_rsa', data.ssh_key.value
            sh.chmod 600, '~/.ssh/id_rsa', echo: false
            sh.raw 'eval `ssh-agent` &> /dev/null'
            sh.raw 'ssh-add ~/.ssh/id_rsa &> /dev/null'

            # BatchMode - If set to 'yes', passphrase/password querying will be disabled.
            # TODO ... how to solve StrictHostKeyChecking correctly? deploy a known_hosts file?
            sh.file '~/.ssh/config', "Host #{data.source_host}\n\tBatchMode yes\n\tStrictHostKeyChecking no\n", append: true
          end

          def download_tarball
            curl = "curl -o #{sanitized_slug}.tar.gz #{oauth_token}-L #{tarball_url}"
            echo = curl.gsub(data.token || /\Za/, '[SECURE]')

            sh.mkdir dir, echo: false, recursive: true
            sh.cmd curl, echo: echo, retry: true
            sh.cmd "tar xfz #{sanitized_slug}.tar.gz"
            sh.mv "#{sanitized_slug}-#{data.commit[0..6]}/*", dir, echo: false
            sh.cd dir
          end

          def git_clone_or_fetch
            disable_interactive_auth
            sh.if "! -d #{dir}/.git" do
              sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, retry: true
            end
            sh.else do
              sh.cmd "git -C #{dir} fetch origin", assert: true, retry: true
              sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
            end
          end

          def disable_interactive_auth
            sh.export 'GIT_ASKPASS', 'echo', :echo => false
          end

          def rm_key
            sh.rm '~/.ssh/source_rsa', force: true, echo: false
          end

          def fetch_ref?
            !!data.ref
          end

          def fetch_ref
            sh.cmd "git fetch origin +#{data.ref}:", assert: true, retry: true
          end

          def git_checkout
            sh.cmd "git checkout -qf #{data.pull_request ? 'FETCH_HEAD' : data.commit}", timing: false
          end

          def submodules?
            config[:git][:submodules]
          end

          def submodules
            sh.if '-f .gitmodules' do
              sh.fold 'git.submodule' do
                sh.file '~/.ssh/config', "Host github.com\n\tStrictHostKeyChecking no\n", append: true
                sh.cmd 'git submodule init'
                sh.cmd "git submodule update #{submodule_update_args}".strip, assert: true, retry: true
              end
            end
          end

          def submodule_update_args
            "--depth=#{config[:git][:submodules_depth].to_s.shellescape}" if config[:git].key?(:submodules_depth)
          end

          def clone_args
            args = "--depth=#{config[:git][:depth].to_s.shellescape}"
            args << " --branch=#{data.branch.shellescape}" unless data.ref
            args
          end

          def use_tarball?
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
      end
    end
  end
end
