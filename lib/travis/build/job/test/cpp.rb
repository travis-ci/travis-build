module Travis
  class Build
    module Job
      class Test
        class Cpp < Test
          class Config < Hashr
            # Travis CI env provides gcc and clang
            define :compiler => "g++"
          end

          def setup
            super

            setup_cxx
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

            def announce_compiler_version
              shell.execute("#{config.compiler} --version")
            end
        end
      end
    end
  end
end
