require 'shellwords'
require 'travis/vcs/perforce/netrc'

module Travis
  module Vcs
    class Perforce < Base
      class Clone < Struct.new(:sh, :data)
        def apply
          sh.fold 'p4.checkout' do
            clone
            sh.cd 'tempdir'
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

          def clone
            sh.export 'P4USER', user, echo: true, assert: false
            sh.export 'P4CHARSET', 'utf8', echo: false, assert: false
            sh.export 'P4PORT', port, echo: false, assert: false            
            sh.cmd 'p4 trust -y'
            if data[:repository][:vcs_type] == 'AssemblaRepository'
              sh.cmd "echo $(p4 info | grep 'Server address:' | cut -d ' ' -f 3- 2>/dev/null)=#{user}:#{ticket} > /tmp/p4ticket", echo: false, assert: false
              sh.export 'P4TICKETS', '/tmp/p4ticket', echo: false, assert: false
            else
              sh.export 'P4PASSWD', ticket, echo: false, assert: false
            end

            return clone_merge if vcs_pull_request?

            sh.cmd "p4 #{p4_opt} client -S //#{dir}/#{checkout_ref} -o | p4 #{p4_opt} client -i"
            sh.cmd "p4 #{p4_opt} sync -p"
          end

          def clone_merge
            sh.cmd "p4 #{p4_opt} client -S //#{dir}/#{pull_request_base_branch} -o | p4 #{p4_opt} client -i"
            sh.cmd "p4 #{p4_opt} sync -p"
            sh.cmd "p4 #{p4_opt} merge //#{dir}/#{pull_request_head_branch}/... //#{dir}/#{pull_request_base_branch}/..."
            sh.cmd "p4 #{p4_opt} resolve -am"
          end

          def p4_opt
            '-v ssl.client.trust.name=1'
          end

          def checkout
            #sh.cmd "p4 -c tempdir switch #{checkout_ref}", timing: false
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
            assembla? ? 'depot' : data.slug.split('/').last
          end

          def port
            data[:repository][:source_url]&.split('/').first
          end

          def user
            data[:repository][:vcs_type] == 'AssemblaRepository' ? data.ssh_key.public_key : data[:sender_login]
          end

          def ticket
            data[:build_token] || data.ssh_key.value
          end

          def config
            data.config
          end

          def assembla?
            @assembla ||= data[:repository][:source_url].include? 'assembla'
          end

          def pull_request_head_branch
            data.job[:pull_request_head_branch].shellescape if data.job[:pull_request_head_branch]
          end

          def pull_request_base_branch
            data.job[:pull_request_base_ref].shellescape if data.job[:pull_request_base_ref]
          end

          def vcs_pull_request?
            data.repository[:vcs_type].to_s == 'AssemblaRepository' && data.pull_request
          end
      end
    end
  end
end
