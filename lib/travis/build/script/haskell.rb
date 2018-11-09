module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {
          cabal: Travis::Build.config.cabal_default.to_s.output_safe,
          ghc: Travis::Build.config.ghc_default.to_s.output_safe
        }.freeze
        GHC_VERSION_ALIASES = Travis::Build.config.ghc_version_aliases_hash.merge(
          'default' => DEFAULTS[:ghc]
        ).freeze

        def configure
          super
          sh.export 'TRAVIS_GHC_DEFAULT', DEFAULTS[:ghc], echo: false
          sh.raw bash('travis_ghc_setup_env')
          sh.raw 'travis_ghc_setup_env'
          sh.raw bash('travis_ghc_find')
          sh.raw bash('travis_ghc_install')

          # Automatic installation of exact versions *only*.
          if version =~ /^(\d+\.\d+\.\d+|head)$/ && cabal_version =~ /^(\d+\.\d+|head)$/
            sh.raw "if [[ ! $(travis_ghc_find #{version} &>/dev/null) || $(cabal --numeric-version 2>/dev/null) != #{cabal_version}* ]]; then"
            sh.raw 'travis_fold start ghc.install'
            sh.echo "Updating ghc-#{version} and cabal-#{cabal_version}", ansi: :yellow
            sh.raw "travis_ghc_install '#{version}' '#{cabal_version}'"
            sh.raw 'travis_fold end ghc.install'
            sh.raw 'fi'
          end
        end

        def setup
          super
          sh.export 'TRAVIS_HASKELL_VERSION', "$(travis_ghc_find '#{version}')"
          sh.export 'PATH', "${TRAVIS_GHC_ROOT}/${TRAVIS_HASKELL_VERSION}/bin:${PATH}", assert: true
          sh.if "-x /opt/ghc/${TRAVIS_HASKELL_VERSION}/bin/ghc" do
            sh.export "PATH", "/opt/ghc/${TRAVIS_HASKELL_VERSION}/bin:${PATH}"
          end
          unless version =~ /\Ahead\z/
            sh.if "! $(ghc --numeric-version 2>/dev/null) = #{version}*" do
              sh.terminate 2, "${ANSI_RED}GHC #{version} not found. Terminating.${ANSI_RESET}"
            end
          end
          sh.if "-x /opt/cabal/#{cabal_version}/bin/cabal" do
            sh.export "PATH", "/opt/cabal/#{cabal_version}/bin:${PATH}"
          end
          unless cabal_version =~ /\Ahead\z/
            sh.if "! $(cabal --numeric-version 2>/dev/null) = #{cabal_version}*" do
              sh.terminate 2, "${ANSI_RED}cabal #{cabal_version} not found. Terminating.${ANSI_RESET}"
            end
          end
          sh.cmd 'cabal update', fold: 'cabal', retry: true
        end

        def announce
          super
          sh.cmd 'ghc --version'
          sh.cmd 'cabal --version'
        end

        def install
          sh.cmd 'cabal install --only-dependencies --enable-tests', fold: 'install', retry: true
        end

        def script
          sh.cmd 'cabal configure --enable-tests && cabal build && cabal test'
        end

        def version
          v = Array(config[:ghc]).first.to_s
          GHC_VERSION_ALIASES.fetch(v, v)
        end

        def cabal_version
          Array(config[:cabal]).first.to_s
        end

        def cache_slug
          super << '--ghc-' << version
        end
      end
    end
  end
end
