module Travis
  module Build
    class Git
      class Netrc < Struct.new(:sh, :data)
        CUSTOM_KEYS = %w(repository_settings travis_yaml)

        def write?
          !custom_ssh_key? && data.prefer_https? && data.token
        end

        def write
          sh.newline

          sh.fold 'git.netrc' do
            sh.echo "Using $HOME/.netrc to clone repository.", ansi: :yellow
            sh.newline
            sh.raw "echo -e \"#{netrc}\" > $HOME/.netrc"
            sh.raw "chmod 0600 $HOME/.netrc"
            sh.raw 'cat $HOME/.netrc | sed \'s/\(login.\{12\}\).*/\1******************************/\' | sed \'s/\(passw.\{12\}\).*/\1******************************/\''
          end
        end

        def delete
          sh.raw "rm -f $HOME/.netrc"
        end

        private

          def netrc
            if data.installation?
              "machine #{source_host_name}\\n  login travis-ci\\n  password #{data.token}\\n"
            else
              "machine #{source_host_name}\\n  login #{data.token}\\n"
            end
          end

          def custom_ssh_key?
            data.ssh_key? && CUSTOM_KEYS.include?(data.ssh_key[:source])
          end

          def source_host_name
            # we will assume that the URL looks like one for git+ssh; e.g., git@github.com:travis-ci/travis-build.git
            match = /[^@]+@(.*):/.match(data.source_url)
            return match[1] if match
            URI.parse(data.source_url).host
          end
      end
    end
  end
end
