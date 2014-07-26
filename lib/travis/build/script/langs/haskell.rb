module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {}

        def setup
          super
          set 'PATH', "/usr/local/ghc/$(ghc_find #{config[:ghc]})/bin/:$PATH"
          cmd 'cabal update', fold: 'cabal', echo: true, retry: true
        end

        def announce
          super
          cmd 'ghc --version', echo: true, timing: false
          cmd 'cabal --version', echo: true, timing: false
        end

        def install
          cmd 'cabal install --only-dependencies --enable-tests', echo: true, retry: true, fold: 'install'
        end

        def script
          cmd 'cabal configure --enable-tests && cabal build && cabal test', echo: true
        end
      end
    end
  end
end
