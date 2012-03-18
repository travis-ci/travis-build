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
            "cabal update && cabal install --enable-tests"
          end

          def script
            "cabal test"
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
