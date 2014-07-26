module Travis
  module Build
    class Script
      class Cpp < Script
        DEFAULTS = {
          compiler: 'g++'
        }

        def cache_slug
          super << "--compiler-" << compiler.to_s.tr('+', 'p')
        end

        def export
          super
          set 'CXX', cxx
          set 'CC', cc # dome projects also need to compile some C, e.g. Rubinius. MK.
        end

        def announce
          super
          cmd "#{compiler} --version", echo: true, timing: false
        end

        def script
          cmd './configure && make && make test', echo: true
        end

        private

          def compiler
            config[:compiler]
          end

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
