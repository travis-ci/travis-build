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
            sh.if "-z $(command -v rebar3)" do
              sh.cmd 'rebar get-deps', fold: 'install', retry: true
            end
          end
        end

        def script
          sh.if "#{rebar_configured} && -f ./rebar" do
            sh.cmd './rebar compile && ./rebar skip_deps=true eunit'
          end
          sh.elif rebar_configured do
            sh.if "-n $(command -v rebar3)" do
              sh.cmd 'rebar3 eunit'
            end
            sh.else do
              sh.cmd 'rebar compile && rebar skip_deps=true eunit'
            end
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
            Array(config[:otp_release]).first.to_s
          end

          def rebar_configured
            '(-f rebar.config || -f Rebar.config)'
          end

          def activate_file
            "${TRAVIS_HOME}/otp/#{otp_release}/activate"
          end

          def archive_name(release)
            "erlang-#{release}-nonroot.tar.bz2"
          end

          def install_erlang(release)
            sh.raw archive_url_for('travis-otp-releases',release, 'erlang').sub(/\.tar\.bz2/, '-nonroot.tar.bz2')
            sh.echo "#{release} is not installed. Downloading and installing pre-build binary.", ansi: :yellow

            sh.echo "Downloading archive: ${archive_url}", ansi: :yellow
            sh.cmd "wget -o ${TRAVIS_HOME}/erlang.tar.bz2 ${archive_url}"
            sh.cmd "mkdir -p ~/otp && tar -xf #{archive_name(release)} -C ~/otp/", echo: true
            sh.cmd "mkdir -p ~/.kerl", echo: true
            sh.cmd "echo '#{release},#{release}' >> ~/.kerl/otp_builds", echo: true
            sh.cmd "echo '#{release} ${TRAVIS_HOME}/otp/#{release}' >> ~/.kerl/otp_builds", echo: true
            sh.raw "rm -f ${TRAVIS_HOME}/erlang.tar.bz2"
          end
      end
    end
  end
end
