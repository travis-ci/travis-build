module Travis
  module Build
    class Script
      class Erlang < Script
        DEFAULTS = {
          otp_release: 'R14B04'
        }

        def export
          super
          set 'TRAVIS_OTP_RELEASE', config[:otp_release]
        end

        def setup
          super
          cmd "source #{HOME_DIR}/otp/#{config[:otp_release]}/activate"
        end

        def install
          # TODO this should use a local ./rebar if exists or rebar otherwise
          # can we just link ./rebar to rebar if it doesn't exist or something?
          uses_rebar? 'rebar get-deps'
        end

        def script
          # TODO this should use a local ./rebar if exists or rebar otherwise
          # can we just link ./rebar to rebar if it doesn't exist or something?
          uses_rebar?(
            then: 'rebar compile && rebar skip_deps=true eunit',
            else: 'make test'
          )
        end

        private

          def uses_rebar?(*args)
            sh_if '-f rebar.config || -f Rebar.config', *args
          end
      end
    end
  end
end
