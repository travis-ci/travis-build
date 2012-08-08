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
            cabal_update
          end

          def install
            "cabal install --enable-tests"
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

            def cabal_update
              shell.execute("cabal update")
            end
        end
      end
    end
  end
end
