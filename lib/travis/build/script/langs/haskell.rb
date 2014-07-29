module Travis
  module Build
    class Script
      class Haskell < Script
        DEFAULTS = {}

        def setup
          super
          sh.export 'PATH', "/usr/local/ghc/$(ghc_find #{config[:ghc]})/bin/:$PATH"
          sh.cmd 'cabal update', fold: 'cabal', echo: true, retry: true
        end

        def announce
          super
          sh.cmd 'ghc --version', echo: true, timing: false
          sh.cmd 'cabal --version', echo: true, timing: false
        end

        def install
          sh.cmd 'cabal install --only-dependencies --enable-tests', echo: true, retry: true, fold: 'install'
        end

        def script
          sh.cmd 'cabal configure --enable-tests && cabal build && cabal test', echo: true
        end
      end
    end
  end
end
