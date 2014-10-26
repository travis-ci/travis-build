module Travis
  module Build
    class Script
      class Rust < Script
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
          sh.newline

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

          sh.cmd 'rustc --version'
          sh.cmd 'cargo --version'
          sh.newline
        end

        def script
          sh.cmd 'cargo build --verbose'
          sh.cmd 'cargo test --verbose'
        end

        private

        def rust_url
          case config[:os]
          when 'osx'
            "https://static.rust-lang.org/dist/rust-#{config[:rust].to_s.shellescape}-x86_64-apple-darwin.tar.gz"
          else
            "https://static.rust-lang.org/dist/rust-#{config[:rust].to_s.shellescape}-x86_64-unknown-linux-gnu.tar.gz"
          end
        end

        def cargo_url
          case config[:os]
          when 'osx'
            'https://static.rust-lang.org/cargo-dist/cargo-nightly-x86_64-apple-darwin.tar.gz'
          else
            'https://static.rust-lang.org/cargo-dist/cargo-nightly-x86_64-unknown-linux-gnu.tar.gz'
          end
        end
      end
    end
  end
end
