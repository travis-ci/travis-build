module Travis
  module Build
    class Script
      class Cpp < Script
        DEFAULTS = {
          compiler: ''
        }

        def export
          super
          sh.export 'CXX', cxx
          sh.export 'CC', cc # some projects also need to compile some C, e.g. Rubinius. MK.
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
            cxx
          end

          def cxx
            case config[:compiler].to_s
            when /^gcc(.*)$/i, /^g\+\+(.*)$/i
              'g++' + $1
            when /^clang([^+]*)$/i, /^clang\+\+(.*)$/i
              'clang++' + $1
            else
              { 'linux' => 'g++', 
                'osx' => 'clang++' }[config[:os]]
            end
          end

          def cc
            case config[:compiler].to_s
            when /^gcc(.*)$/i, /^g\+\+(.*)$/i
              'gcc' + $1
            when /^clang([^+]*)$/i, /^clang\+\+(.*)$/i
              'clang' + $1
            else
              { 'linux' => 'gcc', 
                'osx' => 'clang' }[config[:os]]
            end
          end
      end
    end
  end
end
