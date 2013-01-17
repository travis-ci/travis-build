module Travis
  module Build
    class Script
      class Erlang < Script
        DEFAULTS = {
          otp_release: 'R14B04'
        }

        def export
          super
          set 'TRAVIS_OTP_RELEASE', config[:otp_release], echo: false
        end

        def setup
          super
          cmd "source #{HOME_DIR}/otp/#{config[:otp_release]}/activate"
        end

        def install
          sh_if   "#{rebar_configured} && -f ./rebar", install_rebar('./')
          sh_elif rebar_configured, install_rebar
        end

        def script
          sh_if   "#{rebar_configured} && -f ./rebar", run_rebar('./')
          sh_elif rebar_configured, run_rebar
          sh_else 'make test'
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
