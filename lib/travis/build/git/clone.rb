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
            sh.cmd "git fsck", assert: false, retry: true if trace_git_commands?
          end
          sh.newline
        end

        private
          TRACE_COMMAND_GIT_TRACE = "GIT_TRACE=true"
          TRACE_COMMAND_STRACE = "strace"
          TRACE_COMMAND_ALL = "all"
          DEFAULT_TRACE_COMMAND = TRACE_COMMAND_GIT_TRACE

          def repo_slug
            data.repository[:slug].to_s
          end

          def owner_login
            repo_slug.split('/').first
          end

          def trace_git_commands_owners
            Travis::Build.config.trace_git_commands_owners.output_safe.split(',')
          end

          def trace_git_commands_slugs
            Travis::Build.config.trace_git_commands_slugs.output_safe.split(',')
          end

          def trace_git_commands?
            trace_git_commands_slugs.include?(repo_slug) || trace_git_commands_owners.include?(owner_login)
          end

          def trace_command
            if Travis::Build.config.trace_command.output_safe == TRACE_COMMAND_ALL
              "GIT_TRACE=true GIT_FLUSH=1 GIT_TRACE_PERFORMANCE=true GIT_TRACE_PACK_ACCESS=true GIT_TRACE_PACKET=true GIT_TRACE_PACK_ACCESS=true strace"
            elsif Travis::Build.config.trace_command.output_safe == TRACE_COMMAND_STRACE
              "strace"
            else
              DEFAULT_TRACE_COMMAND
            end
          end

          def git_cmd
            trace_git_commands? ? "#{trace_command} git" : "git"
          end

          def git_clone
            sh.cmd "#{git_cmd} clone #{clone_args} #{data.source_url} #{dir}", assert: false, retry: true
          end

           def git_fetch
            sh.cmd "#{git_cmd} -C #{dir} fetch origin#{fetch_args}", assert: true, retry: true
          end

          def clone_or_fetch
            if autocrlf_key_given?
              sh.cmd "git config --global core.autocrlf #{config[:git][:autocrlf].to_s}"
            end
            sh.if "! -d #{dir}/.git" do
              if sparse_checkout
                sh.echo "Cloning with sparse checkout specified with #{sparse_checkout}", ansi: :yellow
                sh.cmd "git init #{dir}", assert: true, retry: true
                sh.cmd "git -C #{dir} config core.sparseCheckout true", assert: true, retry: true
                sh.cmd "echo #{sparse_checkout} >> #{dir}/.git/info/sparse-checkout", assert: true, retry: true
                sh.cmd "git -C #{dir} remote add origin #{data.source_url}", assert: true, retry: true
                sh.cmd "git -C #{dir} pull origin #{branch} #{pull_args}", assert: false, retry: true
                sh.cmd "cat #{dir}/#{sparse_checkout} >> #{dir}/.git/info/sparse-checkout", assert: true, retry: true
                sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
              else
                git_clone
              end
            end
            sh.else do
              git_fetch
              sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
            end
          end

          def fetch_ref
            sh.cmd "#{git_cmd} fetch origin +#{data.ref}:#{fetch_args}", assert: true, retry: true
          end

          def fetch_ref?
            !!data.ref
          end

          def checkout
            return fetch_head_alternative if vcs_pull_request?
            sh.cmd "git checkout -qf #{checkout_ref}", timing: false
          end

          def checkout_ref
            return 'FETCH_HEAD' if data.pull_request
            return tag if data.tag
            data.commit
          end

          def fetch_head_alternative
            sh.cmd "#{git_cmd} fetch -q #{data.source_url}/branch/#{pull_request_head_branch}", timing: false
            sh.cmd "#{git_cmd} checkout -q FETCH_HEAD", timing: false
            sh.cmd "#{git_cmd} checkout -qb #{pull_request_head_branch}", timing: false
            sh.cmd "#{git_cmd} merge --squash #{branch}", timing: false
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

          def autocrlf_key_given?
            config[:git].key?(:autocrlf)
          end

          def branch
            data.branch.shellescape if data.branch
          end

          def pull_request_head_branch
            data.job[:pull_request_head_branch].shellescape if data.job[:pull_request_head_branch]
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

          def vcs_pull_request?
            data.repository[:vcs_type].to_s != '' && data.repository[:vcs_type].to_s != 'GithubRepository' && data.pull_request
          end
      end
    end
  end
end
