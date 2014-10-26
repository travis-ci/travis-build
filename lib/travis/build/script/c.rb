module Travis
  module Build
    class Script
      class C < Script
        DEFAULTS = {
          compiler: 'gcc'
        }

        def export
          super
          sh.export 'CC', config[:compiler]
        end

        def announce
          super
          sh.cmd "#{config[:compiler]} --version"
        end

        def script
          sh.cmd './configure && make && make test'
        end

        def cache_slug
          super << '--compiler-' << config[:compiler].to_s
        end
      end
    end
  end
end
