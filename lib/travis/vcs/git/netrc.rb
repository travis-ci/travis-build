module Travis
  module Vcs
    class Git < Base
      class Netrc < Struct.new(:sh, :data)
        def apply
          sh.echo "Using ${TRAVIS_HOME}/#{netrc_filename} to clone repository."
          sh.raw "echo -e #{Shellwords.escape netrc_content} > ${TRAVIS_HOME}/#{netrc_filename}"
          sh.raw "chmod 0600 ${TRAVIS_HOME}/#{netrc_filename}"
        end

        def delete
          sh.raw "rm -f ${TRAVIS_HOME}/#{netrc_filename}"
          # host = Shellwords.escape(data.source_host)
          # file_path = "${TRAVIS_HOME}/#{netrc_filename}"

          # if netrc_filename == '_netrc'
          #   # Windows
          #   sh.raw %(
          #     powershell -Command "
          #       (Get-Content #{file_path}) |
          #         Where-Object { $_ -notmatch 'login|password' } |
          #         Set-Content #{file_path}
          #     "
          #   )
          # else
          #   # Linux/macOS
          #   sh.raw "sed -i '/^machine #{host}/,/^$/ { /login/d; /password/d; }' #{file_path}"
          # end
        end

        private

          def netrc_content
            if data.installation?
              "machine #{data.source_host}\n  login travis-ci\n  password #{data.token}\n"
            else
              "machine #{data.source_host}\n  login #{data.token}\n"
            end
          end

          def netrc_filename
            data.config[:os].to_s.downcase == 'windows' ? '_netrc' : '.netrc'
          end
      end
    end
  end
end
