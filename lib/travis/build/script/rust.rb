module Travis
  module Build
    class Script
      class Rust < Script
        RUST_RUSTUP = 'https://sh.rustup.rs'
        RUSTUP_CMD = "curl -sSf https://sh.rustup.rs | sh -s -- --default-toolchain=$TRAVIS_RUST_VERSION --profile=minimal -y"

        DEFAULTS = {
          rust: 'stable',
        }

        CARGO_CACHE_CLEANUP_DIRS = %W(
          $HOME/.cargo/registry/src
        )

        def export
          super

          sh.export 'TRAVIS_RUST_VERSION', version.shellescape, echo: false
        end

        def setup_cache
          if data.cache?(:cargo) && !cache_dirs.empty?
            sh.fold 'cache.cargo' do
              directory_cache.add cache_dirs
            end
          end

          sh.fold('rustup-install') do
            sh.echo 'Installing Rust', ansi: :yellow
            unless app_host.empty?
              sh.cmd "curl -sSf https://#{app_host}/files/rustup-init.sh | sh -s -- --default-toolchain=$TRAVIS_RUST_VERSION --profile=minimal -y", echo: true, assert: false
              sh.if "$? -ne 0" do
                sh.cmd RUSTUP_CMD, echo: true, assert: true
              end
            else
              sh.cmd RUSTUP_CMD, echo: true, assert: true
            end
            sh.export 'PATH', "${TRAVIS_HOME}/.cargo/bin:$PATH"
            if version =~ /nightly|stable|beta/
              sh.cmd 'rustup update', echo: true
            end
          end
        end

        def announce
          super

          sh.cmd 'rustc --version',  assert: true
          sh.cmd 'rustup --version', assert: true
          sh.cmd 'cargo --version',  assert: true
          sh.newline
        end

        def script
          sh.cmd 'cargo build --verbose'
          sh.cmd 'cargo test --verbose'
        end

        def cache_slug
          super << "--cargo-" << version
        end

        def use_directory_cache?
          super || data.cache?(:cargo)
        end

        def before_cache
          sh.cmd "rm -rf \"#{CARGO_CACHE_CLEANUP_DIRS.join(" ")}\"", timing: false, echo: false
        end

        private

          def version
            Array(config[:rust]).first.to_s
          end

          def cache_dirs
            case config[:os]
            when 'linux'
              %W(
                ${TRAVIS_HOME}/.cargo
                target
                ${TRAVIS_HOME}/.rustup
                ${TRAVIS_HOME}/.cache/sccache
              )
            when 'osx'
              %W(
                ${TRAVIS_HOME}/.cargo
                target
                ${TRAVIS_HOME}/.rustup
                ${TRAVIS_HOME}/Library/Caches/Mozilla.sccache
              )
            else
              []
            end
          end
      end
    end
  end
end
