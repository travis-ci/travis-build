module Travis
  class Build
    module Job
      class Test
        class Cpp < Test
          log_header { [Thread.current[:log_header], "build:job:test:cpp"].join(':') }

          class Config < Hashr
            # Travis CI env provides gcc and clang
            define :compiler => "g++"
          end

          def setup
            super

            setup_cxx
            # come projects also need to compile some C, Rubinius is one
            # example. MK.
            setup_cc
            announce_compiler_version
          end

          def install
            nil
          end

          def script
            './configure && make && make test'
          end

          protected

            def setup_cxx
              cxx = case config.compiler
                    when /^gcc/i, /^g++/i then
                      "g++"
                    when /^clang/i, /^clang++/i then
                      "clang++"
                    else
                      "g++"
                    end

              shell.export_line "CXX=#{cxx}"
            end

            def setup_cc
              cc = case config.compiler
                    when /^gcc/i, /^g++/i then
                      "gcc"
                    when /^clang/i, /^clang++/i then
                      "clang"
                    else
                      "gcc"
                    end

              shell.export_line "CC=#{cc}"
            end

            def announce_compiler_version
              shell.execute("#{config.compiler} --version")
            end
        end
      end
    end
  end
end
