module Travis
  module Build
    class Script
      class Cpp < Script
        DEFAULTS = {
          compiler: ''
        }

        def export
          super
          sh.export 'TRAVIS_COMPILER', compiler
          sh.export 'CXX', cxx
          sh.export 'CXX_FOR_BUILD', cxx
          sh.export 'CC', cc # some projects also need to compile some C, e.g. Rubinius. MK.
          sh.export 'CC_FOR_BUILD', cc
          if data.cache?(:ccache)
            sh.export 'PATH', "/usr/lib/ccache:$PATH"
          end
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
            cxx
          end

          def cxx
            case config[:compiler].to_s
            when /^gcc(.*)$/i, /^g\+\+(.*)$/i
              'g++' + $1
            when /^clang([^+]*)$/i, /^clang\+\+(.*)$/i
              'clang++' + $1
            else
              case config[:os]
              when 'osx'
                'clang++'
              when 'linux'
                'g++'
              end
            end
          end

          def cc
            case config[:compiler].to_s
            when /^gcc(.*)$/i, /^g\+\+(.*)$/i
              'gcc' + $1
            when /^clang([^+]*)$/i, /^clang\+\+(.*)$/i
              'clang' + $1
            else
              case config[:os]
              when 'osx'
                'clang'
              when 'linux'
                'gcc'
              end
            end
          end
      end
    end
  end
end
