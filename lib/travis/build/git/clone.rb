require 'shellwords'

module Travis
  module Build
    class Git
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'git.checkout' do
            clone_or_fetch
            sh.cd dir
            fetch_ref if fetch_ref?
            checkout
          end
        end

        private

          def clone_or_fetch
            sh.if "! -d #{dir}/.git" do
              if sparseCheckout?
                sh.cmd "git init #{dir}", assert: true, retry: true
                sh.cmd "git -C #{dir} config core.sparseCheckout true", assert: true, retry: true
                sh.cmd "echo #{sparseCheckout} >> #{dir}/.git/info/sparseCheckout", assert: true, retry: true
                sh.cmd "git -C #{dir} remote add origin #{data.source_url}", assert: true, retry: true
                sh.cmd "git -C #{dir} pull origin #{branch} #{pull_args}", assert: true, retry: true
                sh.cmd "cat #{sparseCheckout} >> #{dir}/.git/info/sparseCheckout", assert: true, retry: true
                sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
              else
                sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, retry: true
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
            sh.cmd "git checkout -qf #{data.pull_request ? 'FETCH_HEAD' : data.commit}", timing: false
          end

          def clone_args
            args = "--depth=#{depth}"
            args << " --branch=#{branch}" unless data.ref
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
            data.branch.shellescape
          end

          def quiet?
            config[:git][:quiet]
          end

          def sparseCheckout
            config[:git][:sparseCheckout]
          end

          def sparseCheckout?
            !!config[:git][:sparseCheckout]
          end

          def dir
            data.slug
          end

          def config
            data.config
          end
      end
    end
  end
end
