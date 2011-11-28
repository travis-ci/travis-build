require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Erlang < Test
          class Config < Hashr
            define :otp_release => 'R14B02'
          end

          extend ActiveSupport::Memoizable

          def setup
            shell.execute "source /home/vagrant/otp/#{config.otp_release}/activate"
          end
          assert :setup

          def install
            './rebar get-deps' if rebar_configured?
          end

          def script
            if rebar_configured?
              './rebar compile && ./rebar skip_deps=true eunit'
            else
              'make test'
            end
          end

          protected

            def rebar_configured?
              shell.file_exists?('rebar.config') || shell.file_exists?('Rebar.config')
            end
            memoize :rebar_configured?
        end
      end
    end
  end
end
