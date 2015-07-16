module Travis
  module Build
    class Script
      class Elixir < Erlang
        DEFAULTS = {
          elixir: '1.0.2',
          otp_release: '17.4'
        }
        KIEX_ELIXIR_HOME = '$HOME/.kiex/elixirs/'
        KIEX_MIX_HOME    = '$HOME/.kiex/mix/'

        def export
          super
          sh.export 'TRAVIS_ELIXIR_VERSION', elixir_version, echo: false
        end

        def announce
          super

          sh.fold "elixir" do
            sh.cmd "kiex list | grep #{Regexp.escape(elixir_version).shellescape}", echo: false, assert: false
            sh.if "$? != 0" do
              sh.echo "Installing Elixir #{elixir_version}"
              sh.cmd "wget http://s3.hex.pm/builds/elixir/v#{elixir_version}.zip", assert: true, timing: true
              sh.cmd "unzip -d #{KIEX_ELIXIR_HOME}/elixir-#{elixir_version} v#{elixir_version}.zip 2>&1 > /dev/null", echo: false
              sh.cmd "echo 'export ELIXIR_VERSION=#{elixir_version}
export PATH=#{KIEX_ELIXIR_HOME}elixir-#{elixir_version}/bin:$PATH
export MIX_ARCHIVES=#{KIEX_MIX_HOME}elixir-#{elixir_version}' > #{KIEX_ELIXIR_HOME}elixir-#{elixir_version}.env"
            end

            sh.cmd "kiex use #{elixir_version}"
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
