module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {}

        def setup
          super
          cmd "export PATH=/usr/local/ghc/$(ghc_find #{config[:ghc]})/bin/:$PATH"
          cmd 'cabal update', fold: 'cabal', retry: true
        end

        def announce
          super
          cmd 'ghc --version'
          cmd 'cabal --version'
        end

        def install
          cmd 'cabal install --only-dependencies --enable-tests', fold: 'install', retry: true
        end

        def script
          cmd 'cabal configure --enable-tests --ghc-options=-Werror && cabal build && cabal test'
        end
      end
    end
  end
end
