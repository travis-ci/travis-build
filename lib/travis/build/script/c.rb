module Travis
  module Build
    class Script
      class C < Script
        DEFAULTS = {
          compiler: 'gcc'
        }

        def export
          super
          sh.export 'TRAVIS_COMPILER', compiler
          sh.export 'CC', compiler
          sh.export 'CC_FOR_BUILD', compiler
          if data.cache?(:ccache)
            sh.export 'PATH', "/usr/lib/ccache:$PATH"
          end
        end

        def configure
          super
          install_compiler(compiler)
        end

        def announce
          super
          sh.cmd "#{compiler} --version"
        end

        def script
          sh.cmd './configure && make && make test'
        end

        def cache_slug
          super << '--compiler-' << compiler
        end

        def setup_cache
          if data.cache?(:ccache)
            sh.fold 'cache.ccache' do
              sh.newline
              directory_cache.add('~/.ccache')
            end
          end
        end

        def use_directory_cache?
          super || data.cache?(:ccache)
        end

        private

          def compiler
            config[:compiler].to_s
          end

          def install_compiler(compiler)
            pkgs = [ compiler, 'libstdc++6' ]

            case compiler
            when /^gcc(-\d+(\.\d+)*)?/
              apt_repo_command = "sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test"
            when /^clang(-\d+(\.\d+)*)?/
              sh.if "$(lsb_release -cs) = trusty" do
                sh.cmd "sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test"
              end
              apt_key_command = "wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -"
              apt_repo_command = "echo \"deb https://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)#{$1} main\"  | sudo tee /etc/apt/sources.list.d/llvm.list >/dev/null"
            else
              sh.echo "Unknown compiler: #{compiler}", ansi: :yellow
              return
            end

            sh.if "! $(command -v #{compiler})" do
              sh.newline
              sh.fold "compiler.install" do
                sh.echo "#{compiler} is not found. Installing"
                sh.if "$(lsb_release -cs) = trusty && #{compiler} =~ ^clang" do
                  sh.cmd "sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test"
                end

                sh.cmd apt_key_command if apt_key_command
                sh.cmd apt_repo_command
                sh.cmd "sudo apt-get update >& /dev/null"
                sh.cmd "sudo apt-get install -y #{pkgs.join(' ')}"
              end
            end
          end
      end
    end
  end
end
