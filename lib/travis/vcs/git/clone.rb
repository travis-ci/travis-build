require 'shellwords'
require 'travis/vcs/git/netrc'

module Travis
  module Vcs
    class Git < Base
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'git.checkout' do
            sh.export 'GIT_LFS_SKIP_SMUDGE', '1' if lfs_skip_smudge?
            sh.cmd 'ssh-keygen -R github.com >/dev/null 2>&1 || true', echo: false
            sh.file '~/.ssh/known_hosts', <<~EOF, append: true, echo: false
              github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
              github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
              github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
            EOF
            install_clone_credential_helper if use_clone_credential_helper?
            clone_or_fetch
            sh.cd dir
            fetch_ref if fetch_ref?
            checkout
            sh.cmd "git fsck", assert: false, retry: true if trace_git_commands?
            remove_clone_credential_helper if use_clone_credential_helper?
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

          # Two independent concerns are layered onto the git invocation:
          #   * credential helper (use_clone_credential_helper?) -- when on, GIT_TERMINAL_PROMPT=0
          #     makes a rejected credential fail FAST instead of falling through to GIT_ASKPASS=echo
          #     (git.rb:disable_interactive_auth) and putting git's own prompt text on the wire, and
          #     the -c credential.helper flags clear any inherited helper and supply the installation
          #     token DIRECTLY rather than via libcurl's netrc parsing (ticket 4655118).
          #   * verbose tracing (trace_git_commands?) -- debug-only, allowlisted, unrelated to the fix.
          # They are gated separately so the fix can go to all installation clones without turning on
          # tracing for everyone.
          def git_cmd
            prefix = +""
            prefix << "GIT_TERMINAL_PROMPT=0 " if use_clone_credential_helper?
            prefix << "#{trace_command} "      if trace_git_commands?
            suffix = use_clone_credential_helper? ? " #{clone_cred_flags}" : ""
            "#{prefix}git#{suffix}"
          end

          # Supply the installation token to git through a credential helper instead of libcurl's
          # netrc parsing. INSTALLATION-TOKEN CLONES ONLY: OAuth clones write a different netrc shape
          # (token in the login field, no password) and must keep using it -- the helper below emits
          # the installation shape (username=x-access-token) and would send the wrong credential for
          # OAuth. Staged rollout: while also gated on trace_git_commands? the helper is limited to
          # the TRACE_GIT_COMMANDS_SLUGS allowlist (gatekeeper canary). TO GO LIVE for all
          # installation-token clones, drop the `&& trace_git_commands?` condition below.
          def use_clone_credential_helper?
            (data.installation? rescue false) && trace_git_commands?
          end

          # Empty-value entry first clears any inherited/system credential.helper; the second points
          # git at our token-supplying helper. useHttpPath=false so one credential covers the repo.
          def clone_cred_flags
            "-c credential.helper= -c credential.helper=#{clone_credential_helper_path} -c credential.useHttpPath=false"
          end

          def clone_credential_helper_path
            "${TRAVIS_HOME}/.git-credential-travis"
          end

          # INSTALLATION-TOKEN CLONES ONLY (gated by use_clone_credential_helper?). Writes a git
          # credential helper that hands git the installation token directly (username=x-access-token)
          # and logs the length + short sha256 of EXACTLY what it emits, taken at git's real
          # credential handoff rather than from the netrc file. The token lives ONLY in an env var
          # exported with echo:false: it never appears on a command line, in the build log, or in
          # `ps`, and (unlike the netrc) is never written to disk. NEVER prints the token itself.
          def install_clone_credential_helper
            sh.export 'TRAVIS_CLONE_TOKEN', data.token.to_s, echo: false
            helper = clone_credential_helper_path
            # Write the helper WITHOUT a heredoc. The shell generator indents every emitted
            # line (generator.rb#indent), and an indented heredoc terminator (<<'EOF') is not
            # recognized -- it swallows the rest of the script and breaks parsing (exit 86).
            # printf keeps each write on ONE logical line, which stays valid at any indent.
            sh.raw "printf '%s\\n' '#!/usr/bin/env bash' '[ \"$1\" = get ] || exit 0' " \
                   "'printf \"username=x-access-token\\n\"' " \
                   "'printf \"password=%s\\n\" \"$TRAVIS_CLONE_TOKEN\"' > #{helper}"
            sh.raw "chmod 0700 #{helper}"
            # Confirmation fingerprint (length + short sha256; the token itself is never printed).
            # DEBUG-ONLY: gated on trace_git_commands? so it does NOT appear in every customer build
            # log once the helper is enabled fleet-wide -- it stays visible for the trace allowlist
            # (gatekeeper canary) and any future debugging.
            if trace_git_commands?
              sh.raw "printf '[git_cred_helper] username=x-access-token credential length=%s sha256=%s\\n' " \
                     "\"${#TRAVIS_CLONE_TOKEN}\" \"$(printf %s \"$TRAVIS_CLONE_TOKEN\" | sha256sum 2>/dev/null | cut -c1-16)\""
            end
          end

          def remove_clone_credential_helper
            sh.raw "rm -f #{clone_credential_helper_path}; unset TRAVIS_CLONE_TOKEN || true"
          end

          def git_clone
            sh.cmd "#{git_cmd} clone #{clone_args} #{data.source_url} #{dir}", assert: false, retry: true
            if vcs_pull_request?
              sh.if "$? -ne 0" do
                sh.cmd "#{git_cmd} clone #{clone_args(true)} #{data.source_url} #{dir}", assert: false, retry: true
              end
            end
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
            sh.cmd "#{git_cmd} fetch -q #{data.source_url} #{pull_request_base_branch}", timing: false  #update branch to pull_request_base_branch

            if pull_request_base_slug && pull_request_head_slug != pull_request_base_slug
              sh.cmd "#{git_cmd} checkout -q FETCH_HEAD", timing: false
              sh.cmd "#{git_cmd} remote add -t #{pull_request_head_branch} upstream #{pull_request_head_url}", timing: false
              sh.cmd "#{git_cmd} fetch upstream", assert: true, retry: true
              sh.cmd "#{git_cmd} merge --squash upstream/#{pull_request_head_branch}", assert: true, retry: true
            else
              sh.cmd "#{git_cmd} fetch origin #{pull_request_head_branch}", timing: false
              sh.cmd "#{git_cmd} branch #{pull_request_head_branch} FETCH_HEAD", timing: false
              sh.cmd "#{git_cmd} checkout #{branch}", timing: false
              sh.cmd "#{git_cmd} merge #{pull_request_head_branch} -m 'Travis CI build'", timing: false
            end
          end

          def clone_args(skip_branch = false)
            branch_name = vcs_pull_request? ? pull_request_base_branch : branch
            args = depth_flag
            args << " --branch=#{tag || branch_name}" unless data.ref || skip_branch
            args << " --quiet" if quiet?
            args << " --single-branch" if skip_branch
            args
          end

          def pull_args
            args = depth_flag
            args << " --quiet" if quiet?
            args
          end

          def fetch_args
            args = " "
            args << depth_flag
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

          def pull_request_base_branch
            data.job[:pull_request_base_ref].shellescape if data.job[:pull_request_base_ref]
          end

          def pull_request_base_slug
            data.job[:pull_request_base_slug].shellescape if data.job[:pull_request_base_slug]
          end

          def pull_request_head_slug
            data.job[:pull_request_head_slug].shellescape if data.job[:pull_request_head_slug]
          end

          def pull_request_head_url
            data.job[:pull_request_head_url].shellescape if data.job[:pull_request_head_url]
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
