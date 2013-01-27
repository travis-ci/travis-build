module Travis
  module Build
    class Script
      class C < Script
        DEFAULTS = {
          compiler: 'gcc'
        }

        def export
          super
          set 'CC', config[:compiler]
        end

        def announce
          super
          cmd "#{config[:compiler]} --version"
        end

        def script
          cmd './configure && make && make test'
        end
      end
    end
  end
end
