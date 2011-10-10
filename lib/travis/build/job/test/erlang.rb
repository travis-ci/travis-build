require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Erlang < Test
          class Config < Hashr
            define :opt_release => 'R14B02'
          end

          extend ActiveSupport::Memoizable

          def setup
            setup_otp
          end

          def install
            rebar_get_deps if rebar_configured?
          end

          protected

            def setup_otp
              shell.execute "source /home/vagrant/otp/#{config.opt_release}/activate"
            end
            assert :setup_otp

            def rebar_configured?
              shell.file_exists?('rebar.config') || shell.file_exists?('Rebar.config')
            end
            memoize :rebar_configured?

            def rebar_get_deps
              shell.execute('./rebar get-deps', :timeout => :install)
            end
            assert :rebar_get_deps

            def script
              if config.script?
                config.script
              elsif rebar_configured?
                './rebar compile && ./rebar skip_deps=true eunit'
              else
                'make test'
              end
            end
        end
      end
    end
  end
end
