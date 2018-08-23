module Travis
  module Build
    class Git
      class Netrc < Struct.new(:sh, :data)
        def apply
          sh.fold 'git.netrc' do
            sh.echo "Using $HOME/.netrc to clone repository.", ansi: :yellow
            sh.newline
            sh.raw "echo -e \"#{netrc}\" > $HOME/.netrc"
            sh.raw "chmod 0600 $HOME/.netrc"
          end
        end

        def delete
          sh.raw "rm -f $HOME/.netrc"
        end

        private

          def netrc
            if data.installation?
              "machine #{data.source_host}\\n  login travis-ci\\n  password #{data.token}\\n"
            else
              "machine #{data.source_host}\\n  login #{data.token}\\n"
            end
          end
      end
    end
  end
end
