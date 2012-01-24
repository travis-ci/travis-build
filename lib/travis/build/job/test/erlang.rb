require 'active_support/memoizable'

module Travis
  class Build
    module Job
      class Test
        class Erlang < Test
          class Config < Hashr
            define :otp_release => 'R14B02'
          end

          def setup
            shell.execute "source /home/vagrant/otp/#{config.otp_release}/activate"
          end
          assert :setup

          def install
            "#{rebar} get-deps" if uses_rebar?
          end

          def script
            if uses_rebar?
              "#{rebar} compile && #{rebar} skip_deps=true eunit"
            else
              'make test'
            end
          end

          protected

          def uses_rebar?
            @uses_rebar ||= (shell.file_exists?('rebar.config') || shell.file_exists?('Rebar.config'))
          end

          def rebar
            if has_local_rebar?
              "./rebar"
            else
              "rebar"
            end
          end

          def has_local_rebar?
            shell.file_exists?('rebar')
          end
        end
      end
    end
  end
end
