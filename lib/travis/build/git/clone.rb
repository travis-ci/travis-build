require 'shellwords'
require 'travis/build/git/netrc'

module Travis
  module Build
    class Git
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'git.checkout' do
            sh.export 'GIT_LFS_SKIP_SMUDGE', '1' if lfs_skip_smudge?
            clone_or_fetch
            sh.cd dir
            fetch_ref if fetch_ref?
            checkout
          end
          sh.newline
        end

        private

          def repo_slug
            data.repository[:slug].to_s
          end

          def owner_login
            repo_slug.split('/').first
          end

          def retry_git_commands_owners
            ENV["RETRY_GIT_COMMANDS_OWNERS"].to_s.split(',')
          end

          def retry_git_commands?
            retry_git_commands_owners.include?(owner_login)
          end

          def retry_timeout_threshold
            ENV["GIT_COMMANDS_RETRY_TIMEOUT_THRESHOLD"] ? ENV["GIT_COMMANDS_RETRY_TIMEOUT_THRESHOLD"] : "5"
          end

          def git_clone
            if retry_git_commands?
              sh.cmd "for i in {1..3}; do travis_wait #{retry_timeout_threshold} git clone #{clone_args} #{data.source_url} #{dir} && break; rm -rf  #{dir}; done", assert: false, retry: true
            else
              sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: false, retry: true
            end
          end

          def git_fetch
            if retry_git_commands?
              sh.cmd "for i in {1..3}; do travis_wait #{retry_timeout_threshold} git -C #{dir} fetch origin#{fetch_args} && break; done", assert: true, retry: true
            else
              sh.cmd "git -C #{dir} fetch origin#{fetch_args}", assert: true, retry: true
            end
          end

          def clone_or_fetch
            sh.if "! -d #{dir}/.git" do
              if sparse_checkout
                sh.echo "Cloning with sparse checkout specified with #{sparse_checkout}", ansi: :yellow
                sh.cmd "git init #{dir}", assert: true, retry: true
                sh.cmd "git -C #{dir} config core.sparseCheckout true", assert: true, retry: true
                sh.cmd "echo #{sparse_checkout} >> #{dir}/.git/info/sparse-checkout", assert: true, retry: true
                sh.cmd "git -C #{dir} remote add origin #{data.source_url}", assert: true, retry: true
                sh.cmd "git -C #{dir} pull origin #{branch} #{pull_args}", assert: false, retry: true
                warn_github_status
                sh.cmd "cat #{dir}/#{sparse_checkout} >> #{dir}/.git/info/sparse-checkout", assert: true, retry: true
                sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
              else
                git_clone
                warn_github_status
              end
            end
            sh.else do
              git_fetch
              sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
            end
          end

          def fetch_ref
            if retry_git_commands?
              sh.cmd "for i in {1..3}; do travis_wait #{retry_timeout_threshold} git fetch origin +#{data.ref}:#{fetch_args} && break; done", assert: true, retry: true
            else
              sh.cmd "git fetch origin +#{data.ref}:#{fetch_args}", assert: true, retry: true
            end
          end

          def fetch_ref?
            !!data.ref
          end

          def checkout
            sh.cmd "git checkout -qf #{checkout_ref}", timing: false
          end

          def checkout_ref
            return 'FETCH_HEAD' if data.pull_request
            return data.tag     if data.tag
            data.commit
          end

          def clone_args
            args = depth_flag
            args << " --branch=#{tag || branch}" unless data.ref
            args << " --quiet" if quiet?
            args
          end

          def pull_args
            args = depth_flag
            args << " --quiet" if quiet?
            args
          end

          def fetch_args
            args = ""
            args << " --quiet" if quiet?
            args
          end

          def depth_flag
            if config[:git][:depth]
              "--depth=#{config[:git][:depth].to_s.shellescape}"
            else
              ""
            end
          end

          def branch
            data.branch.shellescape if data.branch
          end

          def tag
            data.tag.shellescape if data.tag
          end

          def quiet?
            config[:git][:quiet]
          end

          def lfs_skip_smudge?
            config[:git][:lfs_skip_smudge] == true
          end

          def sparse_checkout
            config[:git][:sparse_checkout]
          end

          def dir
            data.slug
          end

          def config
            data.config
          end

          def warn_github_status
            return unless github?

            sh.if "$? -ne 0" do
              sh.echo "Failed to clone from GitHub.", ansi: :red
              sh.echo "Checking GitHub status (https://status.github.com/api/last-message.json):"
              sh.raw "curl -sL https://status.github.com/api/last-message.json | jq -r .[]"
              sh.raw "travis_terminate 1"
            end
          end

          def github?
            host = data.source_host.to_s.downcase
            host == 'github.com' || host.end_with?('.github.com')
          end
      end
    end
  end
end
