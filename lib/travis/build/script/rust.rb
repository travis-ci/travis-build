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

          cmd 'echo -e "\033[33;1mDownloading Rust\033[0m"', assert: false, echo: false
          cmd "curl -sL #{rust_url} | sudo tar --strip-components=1 -C /usr -xzf -"

          cmd 'echo -e "\033[33;1mDownloading Cargo\033[0m"', assert: false, echo: false
          cmd "curl -sL #{cargo_url} | sudo tar --strip-components=1 -C /usr -xzf -"
        end

        def announce
          super

          cmd "rustc --version"
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
