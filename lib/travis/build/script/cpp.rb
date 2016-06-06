module Travis
  module Build
    class Script
      class Cpp < Script
        DEFAULTS = {
          compiler: 'g++'
        }
        LLVM_APT_REPO_MSG = "The LLVM APT rpository is currently available. " \
          "Your builds may fail if your build updates LLVM/clang to a newer version with 'apt'. " \
          "Please see https://github.com/travis-ci/travis-ci/issues/6120#issuecomment-224072540 for a workaround."

        def export
          super
          sh.export 'CXX', cxx
          sh.export 'CC', cc # some projects also need to compile some C, e.g. Rubinius. MK.
          if data.cache?(:ccache)
            sh.export 'PATH', "/usr/lib/ccache:$PATH"
          end
        end

        def announce
          super
          if compiler.include? 'clang'
            sh.echo LLVM_APT_REPO_MSG, ansi: :yellow
          end
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
              sh.echo ''
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
            when /^gcc/i, /^g\+\+/i then
              'g++'
            when /^clang/i, /^clang\+\+/i then
              'clang++'
            else
              'g++'
            end
          end

          def cc
            case compiler
            when /^gcc/i, /^g\+\+/i then
              'gcc'
            when /^clang/i, /^clang\+\+/i then
              'clang'
            else
              'gcc'
            end
          end
      end
    end
  end
end
