module Travis
  module Build
    class Script
      class Rust < Script
        RUST_RUSTUP = 'https://static.rust-lang.org/rustup.sh'

        DEFAULTS = {
          rust: 'nightly',
        }

        def export
          super

          sh.export 'TRAVIS_RUST_VERSION', config[:rust].to_s.shellescape, echo: false
        end

        def setup
          super

          sh.cmd 'mkdir -p ~/rust-installer', echo: false
          sh.echo ''

          sh.fold('rust-download') do
            sh.echo 'Installing Rust', ansi: :yellow
            # Installing docs takes more time and space and we don't need them
            sh.cmd ("curl -sL #{RUST_RUSTUP} | sh --prefix=~/rust --spec=%s --without=rust-docs" % version.shellescape)
          end

          sh.cmd 'export PATH="$PATH:$HOME/rust/bin"', assert: false, echo: false
          sh.cmd 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/rust/lib"', assert: false, echo: false
          sh.cmd 'export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:$HOME/rust/lib"', assert: false, echo: false
        end

        def announce
          super

          sh.cmd 'rustc --version'
          sh.cmd 'cargo --version'
          sh.echo ''
        end

        def script
          sh.cmd 'cargo build --verbose'
          sh.cmd 'cargo test --verbose'
        end

        private

          def version
            config[:rust].to_s
          end
      end
    end
  end
end
