require 'shellwords'
require 'uri'

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
              sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, retry: true
              if github?
                sh.if "$? -ne 0" do
                  sh.echo "Failed to clone from GitHub.", ansi: :red
                  sh.echo "Checking GitHub status (https://status.github.com/api/last-message.json):"
                  sh.raw "curl -sL https://status.github.com/api/last-message.json | jq .[]"
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

          def github?
            if md = /[^@]+@(.*):/.match(data.source_url)
              # we will assume that the URL looks like one for git+ssh; e.g., git@github.com:travis-ci/travis-build.git
              host = md[1]
            else
              host = URI.parse(data.source_url).host.downcase
            end
            host == 'github.com' || host.end_with?('.github.com')
          end
      end
    end
  end
end
