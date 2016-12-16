module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {
          ghc: Travis::Build.config.ghc_default.untaint
        }

        def configure
          super
          sh.raw(
            template(
              'haskell.sh',
              default_ghc: DEFAULTS[:ghc],
              root: '/'
            )
          )
          sh.raw "if ! travis_ghc_find #{version} &>/dev/null; then"
          sh.echo "#{version} is not installed; attempting installation", ansi: :yellow
          sh.raw "travis_ghc_install #{version}"
          sh.raw 'fi'
        end

        def setup
          super
          sh.export 'TRAVIS_HASKELL_VERSION', "$(travis_ghc_find #{version})"
          sh.export 'PATH', "${TRAVIS_GHC_ROOT}/${TRAVIS_HASKELL_VERSION}/bin:${PATH}", assert: true
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
          config[:ghc].to_s
        end
      end
    end
  end
end
