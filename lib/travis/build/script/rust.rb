module Travis
  module Build
    class Script
      class Rust < Script
        RUST_URLS = {
          osx:   'https://static.rust-lang.org/dist/rust-%s-x86_64-apple-darwin.tar.gz',
          linux: 'https://static.rust-lang.org/dist/rust-%s-x86_64-unknown-linux-gnu.tar.gz'
        }

        CARGO_URLS = {
          osx:   'https://static.rust-lang.org/cargo-dist/cargo-nightly-x86_64-apple-darwin.tar.gz',
          linux: 'https://static.rust-lang.org/cargo-dist/cargo-nightly-x86_64-unknown-linux-gnu.tar.gz'
        }

        DEFAULTS = {
          rust: 'nightly',
        }

        def export
          super

          sh.export 'TRAVIS_RUST_VERSION', config[:rust].to_s.shellescape, echo: false
        end

        def setup
          super

          sh.cmd 'mkdir -p ~/rust', echo: false
          sh.echo ''

          sh.fold('rust-download') do
            sh.echo 'Installing Rust and Cargo', ansi: :yellow
            sh.cmd "curl -sL #{rust_url} | tar --strip-components=1 -C ~/rust -xzf -"
            sh.cmd "curl -sL #{cargo_url} | tar --strip-components=1 -C ~/rust -xzf -"
          end

          sh.cmd 'export PATH="$PATH:$HOME/rust/bin"', assert: false, echo: false
          sh.cmd 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/rust/lib"', assert: false, echo: false
        end

        def announce
          super

          sh.cmd 'rustc --version', timing: true
          sh.cmd 'cargo --version', timing: true
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

          def os
            config[:os] == 'osx' ? :osx : :linux
          end

          def rust_url
            RUST_URLS[os] % version.shellescape
          end

          def cargo_url
            CARGO_URLS[os] % version.shellescape
          end
      end
    end
  end
end
