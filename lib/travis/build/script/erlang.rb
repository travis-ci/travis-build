module Travis
  module Build
    class Script
      class Erlang < Script
        DEFAULTS = {
          otp_release: 'R14B04'
        }

        def export
          super
          sh.export 'TRAVIS_OTP_RELEASE', config[:otp_release], echo: false
        end

        def setup
          super
          sh.cmd "source #{HOME_DIR}/otp/#{config[:otp_release]}/activate"
        end

        def install
          sh.if   "#{rebar_configured} && -f ./rebar", install_rebar('./'), fold: 'install', retry: true
          sh.elif rebar_configured, install_rebar, fold: 'install', retry: true
        end

        def script
          sh.if   "#{rebar_configured} && -f ./rebar", run_rebar('./')
          sh.elif rebar_configured, run_rebar
          sh.else 'make test'
        end

        def cache_slug
          super << '--otp-' << config[:otp_release].to_s
        end

        private

          def rebar_configured
            '(-f rebar.config || -f Rebar.config)'
          end

          def install_rebar(path = nil)
            "#{path}rebar get-deps"
          end

          def run_rebar(path = nil)
            "#{path}rebar compile && #{path}rebar skip_deps=true eunit"
          end
      end
    end
  end
end
