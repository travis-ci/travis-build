module Travis
  module Build
    class Script
      module Addons
        class Firefox
          SUPER_USER_SAFE = false

          attr_reader :sh, :version

          def initialize(sh, version)
            @sh = sh
            @version = version
          end

          def before_install
            sh.fold 'install_firefox' do
              sh.echo "Installing Firefox v#{version}", ansi: :yellow
              sh.raw "sudo mkdir -p #{install_dir}"
              sh.raw "sudo chown -R travis #{install_dir}"
              sh.cmd "wget -O #{tmp_file} #{source_url}", retry: true
              sh.raw "pushd #{install_dir}"
              sh.raw "tar xf #{tmp_file}"
              sh.raw "sudo ln -sf #{install_dir}/firefox/firefox /usr/local/bin/firefox"
              sh.raw "sudo ln -sf #{install_dir}/firefox/firefox-bin /usr/local/bin/firefox-bin"
              sh.raw "popd"
            end
          end

          private

            def install_dir
              "/usr/local/firefox-#{version}"
            end

            def source_url
              "http://releases.mozilla.org/pub/firefox/releases/#{version}/linux-x86_64/en-US/firefox-#{version}.tar.bz2"
            end

            def tmp_file
              '/tmp/firefox.tar.bz2'
            end
        end
      end
    end
  end
end
