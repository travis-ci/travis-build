module Travis
  module Build
    class Script
      class Cpp < Script
        DEFAULTS = {
          compiler: 'g++'
        }

        def cache_slug
          super << "--compiler-" << config[:compiler].to_s.tr('+', 'p')
        end

        def export
          super
          set 'CXX', cxx
          set 'CC', cc # come projects also need to compile some C, e.g. Rubinius. MK.
        end

        def announce
          super
          cmd "#{config[:compiler]} --version"
        end

        def script
          cmd './configure && make && make test'
        end

        private

          def cxx
            case config[:compiler]
            when /^gcc/i, /^g\+\+/i then
              'g++'
            when /^clang/i, /^clang\+\+/i then
              'clang++'
            else
              'g++'
            end
          end

          def cc
            case config[:compiler]
            when /^gcc/i, /^g\+\+/i then
              "gcc"
            when /^clang/i, /^clang\+\+/i then
              "clang"
            else
              "gcc"
            end
          end
      end
    end
  end
end
