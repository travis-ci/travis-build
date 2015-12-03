module Travis
  module Build
    class Script
      class C < Script
        DEFAULTS = {
          compiler: 'gcc'
        }

        def export
          super
          sh.export 'CC', compiler
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

        def install
          super
          unless setup_cache_has_run_for[:c]
            setup_cache
          end
        end

        def setup_cache
          return if setup_cache_has_run_for[:c]

          if data.cache?(:ccache)
            sh.fold 'cache.ccache' do
              sh.echo ''
              directory_cache.add('~/.ccache')
            end
          end

          setup_cache_has_run_for[:c] = true
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
