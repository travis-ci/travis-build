module Travis
  module Build
    class Script
      class Rust < Script
        RUST_RUSTUP = 'https://static.rust-lang.org/rustup.sh'

        DEFAULTS = {
          rust: 'stable',
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
            sh.cmd "curl -sL #{RUST_RUSTUP} -o ~/rust-installer/rustup.sh"
            # We silence the stderr of rustup.sh for now, as it has a very verbose progress bar
            sh.cmd "sh ~/rust-installer/rustup.sh #{rustup_args} 2> /dev/null"
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

          def rustup_args
            "--prefix=~/rust --spec=%s -y --disable-sudo" % version.shellescape
          end
      end
    end
  end
end
