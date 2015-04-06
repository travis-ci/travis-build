module Travis
  module Build
    class Script
      class Elixir < Erlang
        DEFAULTS = {
          elixir: '1.0.2',
          otp_release: '17.4'
        }

        def export
          super
          sh.export 'TRAVIS_ELIXIR_VERSION', elixir_version, echo: false
        end

        def announce
          super
          sh.fold "kiex" do
            sh.cmd "kiex list | grep -F #{elixir_version} >/dev/null", echo: false
            sh.if "$? -eq 0" do
              sh.echo "Using Elixir #{elixir_version}", ansi: :yellow
            end
            sh.else do
              sh.echo "Installing Elixir #{elixir_version}", ansi: :yellow
              sh.cmd "travis_retry kiex install #{elixir_version} && kiex use #{elixir_version}"
            end
          end
          sh.cmd "elixir --version"
        end

        def install
          sh.cmd 'mix local.hex --force'
          sh.cmd 'mix deps.get'
        end

        def script
          sh.cmd 'mix test'
        end

        def cache_slug
          super << '--elixir-' << elixir_version
        end

        private

        def elixir_version
          config[:elixir].to_s
        end
      end
    end
  end
end
