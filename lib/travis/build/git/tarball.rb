module Travis
  module Build
    class Git
      class Tarball < Struct.new(:sh, :data)
        def apply
          mkdir
          download
          extract
          move
        end

        private

          def mkdir
            sh.mkdir dir, echo: false, recursive: true
          end

          def download
            cmd  = "curl -o #{filename} #{oauth_token}-L #{tarball_url}"
            echo = cmd.gsub(data.token || /\Za/, '[SECURE]')
            sh.cmd cmd, echo: echo, retry: true
          end

          def extract
            sh.cmd "tar xfz #{filename}"
          end

          def move
            sh.mv "#{basename}-#{data.commit[0..6]}/*", dir, echo: false
            sh.cd dir
          end

          def dir
            data.slug
          end

          def filename
            "#{basename}.tar.gz"
          end

          def basename
            data.slug.gsub('/', '-')
          end

          def tarball_url
            "#{data.api_url}/tarball/#{data.commit}"
          end

          def oauth_token
            data.token ? "-H \"Authorization: token #{data.token}\" " : nil
          end
      end
    end
  end
end
