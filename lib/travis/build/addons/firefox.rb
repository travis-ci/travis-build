require 'shellwords'
require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Firefox < Base
        SUPER_USER_SAFE = true

        # def after_prepare
        def before_before_install
          sh.fold 'install_firefox' do
            sh.echo "Installing Firefox v#{version}", ansi: :yellow
            sh.mkdir install_dir, echo: false, recursive: true
            sh.chown 'travis', install_dir, recursive: true
            sh.cd install_dir, echo: false, stack: true
            sh.cmd "wget -O /tmp/#{filename} #{source_url}", echo: true, timing: true, retry: true
            sh.cmd "tar xf /tmp/#{filename}"
            sh.export 'PATH', "#{install_dir}/firefox:\$PATH", echo: false
            sh.cd :back, echo: false, stack: true
          end
        end

        private

          def version
            config.to_s.shellescape
          end

          def install_dir
            "#{HOME_DIR}/firefox-#{version}"
          end

          def filename
            "firefox-#{version}.tar.bz2"
          end

          def source_url
            "http://download.cdn.mozilla.net/pub/firefox/releases/#{version}/linux-x86_64/en-US/#{filename}"
          end

          def tmp_file
            '/tmp/firefox.tar.bz2'
          end
      end
    end
  end
end
