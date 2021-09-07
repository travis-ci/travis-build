require 'shellwords'
require 'travis/vcs/perforce/netrc'

module Travis
  module Vcs
    class Perforce < Base
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'p4.checkout' do
            clone
            sh.cd dir
            checkout
          end
          sh.newline
        end

        private
          DEFAULT_TRACE_COMMAND = ''

          def repo_slug
            data.repository[:slug].to_s
          end

          def owner_login
            repo_slug.split('/').first
          end

          def trace_p4_commands?
            false
          end

          def trace_command
            DEFAULT_TRACE_COMMAND
          end

          def p4_cmd
            trace_p4_commands? ? "#{trace_command} p4" : "p4"
          end

          def p4_clone
            sh.cmd "#{p4_cmd} clone #{clone_args} #{data.source_url} #{dir}", assert: false, retry: true
          end

          def checkout
            sh.cmd "p4 switch #{checkout_ref}", timing: false
          end

          def checkout_ref
            return branch if data.branch
            return tag if data.tag
            data.commit
          end

          def clone_args
            args = " -p #{host}"
            args << " -r #{remote}"
            args << " -v" if trace_p4_commands?
            args
          end

          def autocrlf_key_given?
            config[:perforce].key?(:autocrlf)
          end

          def host
            config[:perforce].host
          end

          def remote
            config[:perforce].remote
          end

          def branch
            data.branch.shellescape if data.branch
          end

          def tag
            data.tag.shellescape if data.tag
          end

          def quiet?
            config[:perforce][:quiet]
          end

          def lfs_skip_smudge?
            config[:perforce][:lfs_skip_smudge] == true
          end

          def sparse_checkout
            config[:perforce][:sparse_checkout]
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
