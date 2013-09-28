module Travis
  module Build
    class Script
      class Erlang < Script
        DEFAULTS = {
          otp_release: 'R14B04'
        }

        def cache_slug
          super << "--otp-" << config[:otp_release].to_s
        end

        def export
          super
          set 'TRAVIS_OTP_RELEASE', config[:otp_release], echo: false
        end

        def setup
          super
          cmd "source #{HOME_DIR}/otp/#{config[:otp_release]}/activate"
        end

        def install
          self.if   "#{rebar_configured} && -f ./rebar", install_rebar('./'), fold: 'install', retry: true
          self.elif rebar_configured, install_rebar, fold: 'install', retry: true
        end

        def script
          self.if   "#{rebar_configured} && -f ./rebar", run_rebar('./')
          self.elif rebar_configured, run_rebar
          self.else 'make test'
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
