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

        def setup
          unless otp_release_requirement_satisfied?
            sh.echo "Erlang/OTP Release #{otp_release} is not supported by Elixir #{elixir_version}. Using OTP Release #{required_otp_version}.", ansi: :yellow
            config[:otp_release] = required_otp_version
          end
          super
        end

        def announce
          super

          sh.fold "elixir" do
            sh.if "! -f #{HOME_DIR}/.kiex/elixirs/elixir-#{elixir_version}.env" do
              archive = "https://repo.hex.pm/builds/elixir/v#{elixir_version}.zip"
              sh.echo "Installing Elixir #{elixir_version}"
              sh.cmd "wget #{archive}", assert: true, timing: true
              sh.cmd "unzip -d #{KIEX_ELIXIR_HOME}/elixir-#{elixir_version} v#{elixir_version}.zip 2>&1 > /dev/null", echo: false
              sh.cmd "echo 'export ELIXIR_VERSION=#{elixir_version}
export PATH=#{KIEX_ELIXIR_HOME}elixir-#{elixir_version}/bin:$PATH
export MIX_ARCHIVES=#{KIEX_MIX_HOME}elixir-#{elixir_version}' > #{KIEX_ELIXIR_HOME}elixir-#{elixir_version}.env"
              sh.raw "rm -f #{archive}"
            end

            sh.cmd "kiex use #{elixir_version}"
          end
          sh.cmd "elixir --version"
        end

        def install
          if elixir_1_3_0_or_higher?
            sh.cmd 'mix local.rebar --force', fold: "install.rebar"
          end
          sh.cmd 'mix local.hex --force', fold: "install.hex"
          sh.cmd 'mix deps.get', fold: "install.deps"
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

        def otp_release_requirement_satisfied?
          !( elixir_1_0_x? &&  otp_release_18_0_or_higher?) &&
          !( elixir_1_2_0_or_higher? && !otp_release_18_0_or_higher?)
        end

        def elixir_1_2_0_or_higher?
          Gem::Version.new(elixir_version) > Gem::Version.new('1.1.999') # use this for pre-release 1.2.0
        end

        def elixir_1_3_0_or_higher?
          Gem::Version.new(elixir_version) > Gem::Version.new('1.2.999') # use this for pre-release 1.3.0
        end

        def elixir_1_0_x?
          Gem::Version.new(elixir_version) < Gem::Version.new('1.1') &&
          Gem::Version.new(elixir_version) >= Gem::Version.new('1.0.0')
        end

        def otp_release_18_0_or_higher?
          Gem::Version.new(otp_release) > Gem::Version.new('17.999')
        end

        def required_otp_version
          elixir_1_2_0_or_higher? ? '18.0' : '17.4'
        end
      end
    end
  end
end
