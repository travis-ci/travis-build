module Travis
  module Build
    class Script
      class Cpp < Script
        DEFAULTS = {
          compiler: 'g++'
        }

        GCC_REGEXP   = /^g(?:cc|\+\+)(-\d+(\.\d+)*)?/i
        CLANG_REGEXP = /^clang(?:\+\+)?(-\d+(\.\d+)*)?/i

        def export
          super
          sh.export 'TRAVIS_COMPILER', compiler
          sh.export 'CXX', "${CXX:-#{cxx}}"
          sh.export 'CXX_FOR_BUILD', "${CXX_FOR_BUILD:-#{cxx}}"
          sh.export 'CC', "${CC:-#{cc}}" # some projects also need to compile some C, e.g. Rubinius. MK.
          sh.export 'CC_FOR_BUILD', "${CC_FOR_BUILD:-#{cc}}"
          if data.cache?(:ccache)
            sh.export 'PATH', "/usr/lib/ccache:$PATH"
          end
        end

        def configure
          super
          install_compiler(cc)
        end

        def announce
          super
          sh.cmd "#{compiler} --version"
        end

        def script
          sh.cmd './configure && make && make test'
        end

        def cache_slug
          super << '--compiler-' << compiler.tr('+', 'p')
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

          def cxx
            case compiler
            when GCC_REGEXP then
              "g++#{$1}"
            when CLANG_REGEXP then
              "clang++#{$1}"
            else
              'g++'
            end
          end

          def cc
            case compiler
            when GCC_REGEXP then
              "gcc#{$1}"
            when CLANG_REGEXP then
              "clang#{$1}"
            else
              'gcc'
            end
          end

          def install_compiler(compiler)
            pkgs = [ compiler, 'libstdc++6' ]

            case compiler
            when GCC_REGEXP
              apt_repo_command = "sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test"
            when CLANG_REGEXP
              sh.if "$(command -v lsb_release) && $(lsb_release -cs) = trusty" do
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
                sh.if "$(command -v lsb_release) && $(lsb_release -cs) = trusty && #{compiler} =~ ^clang" do
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
