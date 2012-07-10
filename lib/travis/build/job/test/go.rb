module Travis
  class Build
    module Job
      class Test
        class Go < Test
          class Config < Hashr
          end

          def setup
            # Here we set up GOPATH + subdirectories structure Go build tool expects.
            # We will just put dependencies here, as source only, via 'go get -d'.
            # The 'go build' step will look for them here, and build them.
            shell.execute "mkdir -p #{gopath}/src"
            shell.export_line "GOPATH=#{gopath}"
          end

          def install
            if uses_make?
              # no-op
            else
              "go get -d -v && go build -v"
            end
          end

          def script
            if uses_make?
              "make"
            else
              "go test -v"
            end
          end

          protected

            def uses_make?
              @uses_make ||= (shell.file_exists?('Makefile'))
            end

            def gopath
              "#{home_directory}/gopath"
            end
        end
      end
    end
  end
end
