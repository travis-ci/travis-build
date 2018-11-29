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
      end
    end
  end
end
