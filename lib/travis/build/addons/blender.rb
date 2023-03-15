require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Blender < Base
        ALLOWED_VERSIONS = %w[3.4.1].freeze

        def after_prepare
          sh.fold 'blender' do
            if data.config[:os] != 'linux'
              sh.echo 'Blender is only available for linux', ansi: :red
              return
            end

            if version.nil?
              sh.echo "Blender: Invalid version '#{raw_version}' given. Valid versions are: #{ALLOWED_VERSIONS.join(', ')}",
                      ansi: :red
              return
            end
            sh.echo "Installing Blender version: #{version}", ansi: :yellow
            sh.cmd 'CURL_USER_AGENT="Travis-CI $(curl --version | head -n 1)"'
            sh.cmd 'mkdir ~/blender'
            sh.cmd "curl -A \"$CURL_USER_AGENT\" -sSf -L --retry 7  https://ftp.halifax.rwth-aachen.de/blender/release/Blender#{version[/\d+\.\d+/]}/blender-#{version}-linux-x64.tar.xz" \
            ' | tar xf - -J -C ~/blender --strip-components 1'
            sh.cmd 'alias blender=~/blender/blender'
          end
        end

        private

        def raw_version
          config.to_s.strip.shellescape
        end

        def version
          ALLOWED_VERSIONS.include?(raw_version) ? raw_version : nil
        end
      end
    end
  end
end