module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {}

        def announce
          super
          cmd 'ghc --version'
          cmd 'cabal --version'
        end

        def install
          # Ideally we would use:
          #
          #   cabal update && cabal install --only-dependencies --enable-tests
          #
          # But this does not properly work with cabal-install 0.10.2.
          # http://www.haskell.org/pipermail/cabal-devel/2012-January/008428.html
          cmd 'cabal update && cabal install'
        end

        def script
          cmd 'cabal configure --enable-tests && cabal build && cabal test'
        end
      end
    end
  end
end
