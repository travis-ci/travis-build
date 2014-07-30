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

          echo "Downloading Rust", ansi: :yellow
          cmd "curl -sL #{rust_url} | tar --strip-components=1 -C ~/rust -xzf -"

          echo "Downloading Cargo", ansi: :yellow
          cmd "curl -sL #{cargo_url} | tar --strip-components=1 -C ~/rust -xzf -"

          cmd 'export PATH="$PATH:$HOME/rust/bin"', assert: false, echo: false
        end

        def announce
          super

          cmd "rustc --version"
        end

        def install
          cmd "cargo build"
        end

        def script
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
