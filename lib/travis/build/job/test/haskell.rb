module Travis
  class Build
    module Job
      class Test
        class Haskell < Test
          log_header { [Thread.current[:log_header], "build:job:test:haskell"].join(':') }

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
