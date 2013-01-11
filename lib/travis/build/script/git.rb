module Travis
  module Build
    class Script
      module Git
        DEFAULTS = {
          git: { submodules: true }
        }

        def checkout
          clone
          ch_dir
          rm_key
          fetch_ref if fetch_ref?
          git_checkout
          submodules if submodules?
          sh.to_s
        end

        private

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
            cmd "git checkout -qf #{data.commit}", assert: true
          end

          def submodules?
            config[:git][:submodules]
          end

          def submodules
            sh_if '-f .gitmodules' do
              cmd 'echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config', echo: false
              cmd 'git submodule init'
              cmd 'git submodule update', assert: true, timeout: :git_submodules
            end
          end

          def clone_args
            args = '--depth=100 --quiet'
            args << " --branch=#{data.branch}" unless data.ref
            args
          end

          def dir
            data.source_url.gsub(/\.git$/, '').split('/')[-2, 2].join('/')
          end
      end
    end
  end
end
