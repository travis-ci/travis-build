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
          sh.export 'TRAVIS_ELIXIR_VERSION', elixir_version, echo: false
        end

        def announce
          super
          sh.cmd "source #{HOME_DIR}/otp/#{otp_release}/activate", assert: true
          if !elixir_version.empty?
            sh.if has_elixir(elixir_version) do
              sh.cmd "source #{exlixir_env_file(elixir_version)}", assert: true
            end
          end
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

          def elixir_version
            config[:elixir].to_s
          end

          def rebar_configured
            '(-f rebar.config || -f Rebar.config)'
          end

          def has_elixir(version)
            "-f #{exlixir_env_file(version)}"
          end

          def exlixir_env_file(version)
            "#{HOME_DIR}/.kiex/elixirs/elixir-#{version}.env"
          end
      end
    end
  end
end
