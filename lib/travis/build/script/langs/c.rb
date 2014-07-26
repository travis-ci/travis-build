module Travis
  module Build
    class Script
      class C < Script
        DEFAULTS = {
          compiler: 'gcc'
        }

        def cache_slug
          super << "--compiler-" << compiler.to_s
        end

        def export
          super
          set 'CC', compiler
        end

        def announce
          super
          cmd "#{compiler} --version", echo: true, timing: false
        end

        def script
          cmd './configure && make && make test', echo: true
        end

        def compiler
          config[:compiler]
        end
      end
    end
  end
end
