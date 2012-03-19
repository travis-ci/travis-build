module Travis
  class Build
    module Job
      class Test
        class Haskell < Test
          class Config < Hashr
          end

          def setup
            super
            announce_ghc
            announce_cabal
          end

          def install

            # Ideally we would use:
            #
            # "cabal update && cabal install --only-dependencies --enable-tests"
            #
            # But this does not properly work with cabal-install 0.10.2.
            #
            # http://www.haskell.org/pipermail/cabal-devel/2012-January/008428.html
            #
            "cabal update && cabal install"
          end

          def script
            "cabal configure --enable-tests && cabal build && cabal test"
          end

          protected

            def announce_ghc
              shell.execute("ghc --version")
            end

            def announce_cabal
              shell.execute("cabal --version")
            end
        end
      end
    end
  end
end
