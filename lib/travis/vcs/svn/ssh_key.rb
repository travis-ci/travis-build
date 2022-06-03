module Travis
  module Vcs
    class Svn < Base
      class SshKey < Struct.new(:sh, :data)
        def apply
          sh.mkdir '~/.ssh', recursive: true, echo: false
          sh.file '~/.ssh/id_rsa', key
          sh.chmod 600, '~/.ssh/id_rsa', echo: false
          sh.raw 'eval `ssh-agent` &> /dev/null'
          sh.raw 'ssh-add ~/.ssh/id_rsa &> /dev/null'

          # BatchMode - If set to 'yes', passphrase/password querying will be disabled.
          # TODO ... how to solve StrictHostKeyChecking correctly? deploy a known_hosts file?
          sh.file '~/.ssh/config', "Host #{source_host}\n\tBatchMode yes\n\tStrictHostKeyChecking no\n\tSendEnv REPO_NAME", append: true
          sh.export 'REPO_NAME', repository_name, echo: false

      	  #TODO why it's not reading the config
          sh.export 'SVN_SSH', '"ssh -o SendEnv=REPO_NAME -o StrictHostKeyChecking=no -l svn"', echo: false if assembla?
        end

        private

          def key
            data[:build_token]
          end

          def repository_name
            repo_slug&.split('/').last
          end

          def repo_slug
            data.repository[:slug].to_s
          end
        
          def source_host
            data.repository[:source_host]
          end

          def assembla?
            @assembla ||= source_host.include? 'assembla'
          end
      end
    end
  end
end
