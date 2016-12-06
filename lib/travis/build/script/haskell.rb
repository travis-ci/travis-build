module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {
          ghc: (ENV['TRAVIS_BUILD_GHC_DEFAULT'] || '7.6.3').untaint
        }

        def setup
          super
          sh.raw(
            template(
              'haskell.sh',
              default_ghc: DEFAULTS[:ghc],
              root: '/'
            )
          )
          sh.export 'PATH', "#{path}:$PATH", assert: true
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

        def path
          "${TRAVIS_GHC_ROOT}/$(travis_ghc_find #{version})/bin"
        end

        def version
          config[:ghc].to_s
        end
      end
    end
  end
end
