module Travis
  class Build
    module Job
      class Test
        class C < Test
          class Config < Hashr
            # Travis CI env provides gcc and clang
            define :compiler => "gcc"
          end

          def setup
            super

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

            def setup_cc
              shell.export_line "CC=#{config.compiler}"
            end

            def announce_compiler_version
              shell.execute("#{config.compiler} --version")
            end
        end
      end
    end
  end
end
