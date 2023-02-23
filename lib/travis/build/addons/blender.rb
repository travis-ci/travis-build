require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Blender < Base
        ALLOWED_VERSIONS = %w[3.4.1].freeze

        def after_prepare
          sh.fold 'blender' do
            if version.nil?
              sh.echo "Blender: Invalid version '#{raw_version}' given. Valid versions are: #{ALLOWED_VERSIONS.join(', ')}",
                      ansi: :red
              return
            end
            sh.echo "Installing Blender version: #{version}", ansi: :yellow
            sh.cmd "curl https://ftp.halifax.rwth-aachen.de/blender/release/Blender#{version[/\d+\.\d+/]}/blender-#{version}-linux-x64.tar.xz --output blender-#{version}-linux-x64.tar.xz"
            sh.cmd "tar -xf blender-#{version}-linux-x64.tar", sudo: false
            sh.cmd "alias blender=$(pwd)/blender-#{version}-linux-x64/blender"
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