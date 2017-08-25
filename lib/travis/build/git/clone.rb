require 'shellwords'
require 'uri'

module Travis
  module Build
    class Git
      class Clone < Struct.new(:sh, :data)
        def apply
          write_netrc if data.prefer_https? && data.token

          sh.fold 'git.checkout' do
            sh.export 'GIT_LFS_SKIP_SMUDGE', '1' if lfs_skip_smudge?
            clone_or_fetch
            delete_netrc
            sh.cd dir
            fetch_ref if fetch_ref?
            checkout
          end
        end

        private

          def clone_or_fetch
            sh.if "! -d #{dir}/.git" do
              if sparse_checkout
                sh.cmd "git init #{dir}", assert: true, retry: true
                sh.cmd "git -C #{dir} config core.sparseCheckout true", assert: true, retry: true
                sh.cmd "echo #{sparse_checkout} >> #{dir}/.git/info/sparseCheckout", assert: true, retry: true
                sh.cmd "git -C #{dir} remote add origin #{data.source_url}", assert: true, retry: true
                sh.cmd "git -C #{dir} pull origin #{branch} #{pull_args}", assert: true, retry: true
                sh.cmd "echo #{sparse_checkout} >> #{dir}/.git/info/sparseCheckout", assert: true, retry: true
                sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
              else
                sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, retry: true
                if github?
                  sh.if "$? -ne 0" do
                    sh.echo "Failed to clone from GitHub.", ansi: :red
                    sh.echo "Checking GitHub status (https://status.github.com/api/last-message.json):"
                    sh.raw "curl -sL https://status.github.com/api/last-message.json | jq -r .[]"
                  end
                end
              end
            end
            sh.else do
              sh.cmd "git -C #{dir} fetch origin", assert: true, retry: true
              sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
            end
          end

          def fetch_ref
            sh.cmd "git fetch origin +#{data.ref}:", assert: true, retry: true
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
            args = "--depth=#{depth}"
            args << " --branch=#{tag || branch}" unless data.ref
            args << " --quiet" if quiet?
            args
          end

          def pull_args
            args = "--depth=#{depth}"
            args << " --quiet" if quiet?
            args
          end

          def depth
            config[:git][:depth].to_s.shellescape
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

          def write_netrc
            sh.newline
            sh.echo "Using $HOME/.netrc to clone repository.", ansi: :yellow
            sh.newline
            sh.raw "echo -e \"machine #{source_host_name}\n  login #{data.token}\\n\" > $HOME/.netrc"
            sh.raw "chmod 0600 $HOME/.netrc"
          end

          def delete_netrc
            sh.raw "rm -f $HOME/.netrc"
          end

          def github?
            source_host_name.downcase == 'github.com' || source_host_name.downcase.end_with?('.github.com')
          end

          def source_host_name
            md = /[^@]+@(.*):/.match(data.source_url)
            if md
              # we will assume that the URL looks like one for git+ssh; e.g., git@github.com:travis-ci/travis-build.git
              host = md[1]
            else
              host = URI.parse(data.source_url).host
            end

            host
          end
      end
    end
  end
end
