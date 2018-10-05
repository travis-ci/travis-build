module Travis
  module Build
    class Git
      class SshKey < Struct.new(:sh, :data)
        def apply
          sh.fold 'ssh_key' do
            sh.echo messages
          end

          sh.mkdir '~/.ssh', recursive: true, echo: false
          sh.file '~/.ssh/id_rsa', key.value
          sh.chmod 600, '~/.ssh/id_rsa', echo: false
          sh.cmd 'eval `ssh-agent`', assert: true
          sh.cmd 'ssh-add ~/.ssh/id_rsa', assert: true

          # BatchMode - If set to 'yes', passphrase/password querying will be disabled.
          # TODO ... how to solve StrictHostKeyChecking correctly? deploy a known_hosts file?
          sh.file '~/.ssh/config', "Host #{data.source_host}\n\tBatchMode yes\n\tStrictHostKeyChecking no\n", append: true
        end

        private

          def key
            data.ssh_key
          end

          def messages
            msgs = ["Installing SSH key#{" from: #{source}" if key.source}"]
            msgs << "Key fingerprint: #{key.fingerprint}" if key.fingerprint
            msgs
          end

          def source
            key.source.gsub(/[_-]+/, ' ')
          end
      end
    end
  end
end
