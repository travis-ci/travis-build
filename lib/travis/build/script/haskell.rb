module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {}

        def setup
          super
          cmd 'cabal update'
        end

        def announce
          super
          cmd 'ghc --version'
          cmd 'cabal --version'
        end

        def install
          cmd 'cabal install --only-dependencies --enable-tests', fold: 'install'
        end

        def script
          cmd 'cabal configure --enable-tests && cabal build && cabal test'
        end
      end
    end
  end
end
