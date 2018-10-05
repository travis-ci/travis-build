module Travis
  module Build
    class Git
      class Netrc < Struct.new(:sh, :data)
        def apply
          sh.fold 'git.netrc' do
            sh.echo "Using ${TRAVIS_HOME}/#{netrc_filename} to clone repository.", ansi: :yellow
            sh.newline
            sh.raw "echo -e \"#{netrc_content}\" > ${TRAVIS_HOME}/#{netrc_filename}"
            sh.raw "chmod 0600 ${TRAVIS_HOME}/#{netrc_filename}"
          end
        end

        def delete
          sh.raw "rm -f ${TRAVIS_HOME}/#{netrc_filename}"
        end

        private

          def netrc_content
            if data.installation?
              "machine #{data.source_host}\\n  login travis-ci\\n  password #{data.token}\\n"
            else
              "machine #{data.source_host}\\n  login #{data.token}\\n"
            end
          end

          def netrc_filename
            data.config[:os].to_s.downcase == 'windows' ? '_netrc' : '.netrc'
          end
      end
    end
  end
end
