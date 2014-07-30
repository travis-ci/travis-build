module Travis
  module Build
    class Script
      class Rust < Script
        DEFAULTS = {
          rust: 'nightly',
        }

        def export
          super

          set 'TRAVIS_RUST_VERSION', config[:rust].to_s.shellescape, echo: false
        end

        def setup
          super

          cmd 'mkdir -p ~/rust', echo: false

          echo ""
          fold("rust-download") do
            echo "Downloading Rust and Cargo", ansi: :yellow
            cmd "curl -sL #{rust_url} | tar --strip-components=1 -C ~/rust -xzf -"
            cmd "curl -sL #{cargo_url} | tar --strip-components=1 -C ~/rust -xzf -"
          end

          cmd 'export PATH="$PATH:$HOME/rust/bin"', assert: false, echo: false
          cmd 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/rust/lib"', assert: false, echo: false
        end

        def announce
          super

          cmd "rustc --version"
          cmd "cargo --version"
        end

        def script
          cmd "cargo build"
          cmd "cargo test"
        end

        private

        def rust_url
          case config[:os]
          when "osx"
            "http://static.rust-lang.org/dist/rust-#{config[:rust].to_s.shellescape}-x86_64-apple-darwin.tar.gz"
          else
            "http://static.rust-lang.org/dist/rust-#{config[:rust].to_s.shellescape}-x86_64-unknown-linux-gnu.tar.gz"
          end
        end

        def cargo_url
          case config[:os]
          when "osx"
            "http://static.rust-lang.org/cargo-dist/cargo-nightly-mac.tar.gz"
          else
            "http://static.rust-lang.org/cargo-dist/cargo-nightly-linux.tar.gz"
          end
        end
      end
    end
  end
end
