module Travis
  module Vcs
    class Svn < Base
      class Tarball < Struct.new(:sh, :data)
        def apply
          sh.fold 'svn.tarball' do
            mkdir
            download
            extract
            move
          end
        end

        private

          def mkdir
            sh.mkdir dir, echo: false, recursive: true
          end

          def download
            cmd  = "curl -o #{filename} #{auth_header}-L #{tarball_url}"
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

          def auth_header
            "-H \"Authorization: token #{data.token}\" " if data.token
          end
      end
    end
  end
end
