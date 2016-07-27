require 'shellwords'

module Travis
  module Build
    class Git
      class Clone < Struct.new(:sh, :data)
        GIT_URL_REGEXP = %r!
          \A(
            (?<git_username>[^@]+)@(?<git_host>[^:]+): # git@github.com:
          |
            (?<protocol>[^:]*://)(?<git_host>[^\/]+)/  # proto://example.com/
          )
          (?<git_path>.*)\z
        !x

        def apply
          sh.fold 'git.checkout' do
            write_netrc
            clone_or_fetch
            sh.cd dir
            fetch_ref if fetch_ref?
            checkout
          end
        end

        private

          def clone_or_fetch
            sh.if "! -d #{dir}/.git" do
              sh.cmd "git clone #{clone_args} #{clone_url} #{dir}", assert: true, retry: true
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

          def depth
            config[:git][:depth].to_s.shellescape
          end

          def branch
            data.branch.shellescape
          end

          def quiet?
            config[:git][:quiet]
          end

          def dir
            data.slug
          end

          def config
            data.config
          end

          def write_netrc
            if data.prefer_https?
              sh.raw "echo -e \"machine github.com\n  login #{data[:oauth_token]}\\n\" > $HOME/.netrc"
              sh.raw "chmod 0600 $HOME/.netrc"
            end
          end

          def clone_url
            if data.prefer_https? && match_data = data.source_url.match(GIT_URL_REGEXP)
              "https://%s/%s" % [ match_data[:git_host], match_data[:git_path] ]
            else
              data.source_url
            end
          end
      end
    end
  end
end
