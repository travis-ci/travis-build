module Travis
  module Build
    class Script
      class Erlang < Script
        DEFAULTS = {
          otp_release: 'R14B04'
        }

        def cache_slug
          super << '--otp-' << otp_release.to_s
        end

        def export
          super
          sh.export 'TRAVIS_OTP_RELEASE', otp_release
        end

        def setup
          super
          sh.cmd "source #{HOME_DIR}/otp/#{otp_release}/activate"
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

        private

          def otp_release
            config[:otp_release]
          end

          def rebar_configured
            '(-f rebar.config || -f Rebar.config)'
          end
      end
    end
  end
end
