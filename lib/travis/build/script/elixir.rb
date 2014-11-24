module Travis
  module Build
    class Script
      class Elixir < Erlang
        DEFAULTS = {
          elixir: '1.0.2',
          otp_release: '17.3'
        }

        def export
          super
          sh.export 'TRAVIS_ELIXIR_VERSION', elixir, echo: false
        end

        def setup
          super
          sh.cmd "kiex use #{elixir}"
        end

        def install
        end

        def script
        end

        def cache_slug
          super << '--elixir-' << elixir
        end

        private

        def elixir
          config[:elixir].to_s
        end
      end
    end
  end
end
