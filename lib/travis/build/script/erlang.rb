module Travis
  module Build
    class Script
      class Erlang < Script
        DEFAULTS = {
          otp_release: 'R14B04'
        }

        def export
          super
          sh.export 'TRAVIS_OTP_RELEASE', otp_release, echo: false
        end

        def setup
          super
          sh.if "! -f #{activate_file}" do
            install_erlang otp_release
          end
          sh.cmd "source #{activate_file}"
        end

        def install
          sh.if "#{rebar_configured} && -f ./rebar" do
            sh.cmd './rebar get-deps', fold: 'install', retry: true
          end
          sh.elif rebar_configured do
            sh.cmd 'rebar get-deps', fold: 'install', retry: true
          end
        end

        def script
          sh.if "#{rebar_configured} && -f ./rebar" do
            sh.cmd './rebar compile && ./rebar skip_deps=true eunit'
          end
          sh.elif rebar_configured do
            sh.cmd 'rebar compile && rebar skip_deps=true eunit'
          end
          sh.else do
            sh.cmd 'make test'
          end
        end

        def cache_slug
          super << '--otp-' << otp_release
        end

        private

          def otp_release
            config[:otp_release].to_s
          end

          def rebar_configured
            '(-f rebar.config || -f Rebar.config)'
          end

          def activate_file
            "#{HOME_DIR}/otp/#{otp_release}/activate"
          end

          def archive_name(release)
            "erlang-#{release}-nonroot.tar.bz2"
          end

          def install_erlang(release)
            sh.echo "#{release} is not installed. Downloading and installing pre-build binary.", ansi: :yellow
            sh.cmd "wget #{archive_url_for('travis-otp-releases',release, 'erlang').sub(/\.tar\.bz2/, '-nonroot.tar.bz2')}"
            sh.cmd "mkdir -p ~/otp && tar -xf #{archive_name(release)} -C ~/otp/"
            sh.cmd "mkdir -p ~/.kerl"
            sh.cmd "echo '#{release},#{release}' >> ~/.kerl/otp_builds", echo: false
            sh.cmd "echo '#{release} #{HOME_DIR}/otp/#{release}' >> ~/.kerl/otp_builds", echo: false
          end
      end
    end
  end
end
