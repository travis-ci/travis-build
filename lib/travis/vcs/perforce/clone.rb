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
              sh.cmd "echo $(p4 info | grep 'Server address:' | cut -d ' ' -f 3- 2>/dev/null)=MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAqsJvVCtGwsOYrxwa5ZH8112KNX+e5bKjnQhQLNwM8e2HLK9oK0eO3bhCCmgBrKJowZPASHa02EJO7L1E3nslS1kCjs8YlipcygwXb8yxJ3uRZnQlwthFa+1zj6j44tYOwKdBkC3i/5rQa8ryi2sdQpJKSJYlFyHLRFqUL+zWwIgQoxo2Tn2P8VB6VSqjJC5UmI84rHtciL7orHVkSPmVyXvNcf3sAiSzLUu/C2/qXn2pFlqjYvIV+iKjowCUInNKimTyfGSeG4F3WvRiltois5q3z0Dy5GeqpCts6lu5cmRdp+YvLfLJKJl/EEkTLP3WcvumuRkuAOX6pxOOBfvhcZ+zdOWzKUJ5sH8QXhjWmN+WodD9D0SI9TSQcFbzeuyZXEK3y+p9vkh+onCbMqr8KnBuqvgtB3aLPCLSrzwAphL+nqYaIPOFXbs58tKwdZuoKptJTOXSor+7IiDKrBiJFUzeqGxPkwdk3sWt/5kbBXkh8SG2pF+c770kF9QxB9uDqSL8nSAaclFH4o3MZhAmQr3ETuFFCjCb8kAwrMiMKgNeK/JCkHo6Z/gVqhg5zdpTHfcWYZzOEUPkZ9Zg6Gix9n8f1i3OXVcAnTVwWqax0IDuYTjq0VHzdIvZTm+jl8Hlb8/qv4PwErqRifhwj7WVJLPryAg2SufM2oFr2uIXwN0CAwEAAQ==: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 > /tmp/.p4tickets", echo: false, assert: false
              sh.export 'P4TICKETS', '/tmp/.p4tickets', echo: false, assert: false
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
            logger.info "data=#{data.pretty_inspect}"
            data[:repository][:vcs_type] == 'AssemblaRepository' ? data.ssh_key.public_key : data[:sender_login]
          end

          def logger
            Build.logger
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
