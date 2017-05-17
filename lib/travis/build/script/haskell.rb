module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {
          cabal: Travis::Build.config.cabal_default.to_s.untaint,
          ghc: Travis::Build.config.ghc_default.to_s.untaint
        }.freeze
        GHC_VERSION_ALIASES = Travis::Build.config.ghc_version_aliases_hash.merge(
          'default' => DEFAULTS[:ghc]
        ).freeze

        def configure
          super
          sh.raw(
            template(
              'haskell.sh',
              default_ghc: DEFAULTS[:ghc],
              default_cabal: DEFAULTS[:cabal],
              root: '/'
            )
          )
          # Automatic installation of exact versions *only*.
          if version =~ /^(\d+\.\d+\.\d+|head)$/ && cabal_version =~ /^(\d+\.\d+|head)$/
            sh.raw "if ! travis_ghc_find '#{version}' &>/dev/null; then"
            sh.raw 'travis_fold start ghc.install'
            sh.echo "ghc-#{version} is not installed; attempting installation", ansi: :yellow
            sh.raw "travis_ghc_install '#{version}' '#{cabal_version}'"
            sh.raw 'travis_fold end ghc.install'
            sh.raw 'fi'
          end
        end

        def setup
          super
          sh.export 'PATH', "/opt/ghc/bin:${TRAVIS_GHC_ROOT}/${TRAVIS_HASKELL_VERSION}/bin:${PATH}", assert: true
          sh.export 'TRAVIS_HASKELL_VERSION', "$(travis_ghc_find '#{version}')"
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
          v = config[:ghc].to_s
          GHC_VERSION_ALIASES.fetch(v, v)
        end

        def cabal_version
          config[:cabal].to_s
        end
      end
    end
  end
end
