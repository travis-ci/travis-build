module Travis
  class Build
    module Job
      class Test
        class Go < Test
          class Config < Hashr
          end

          def setup
            # Here we set up GOPATH + subdirectories structure Go build tool expects
            shell.execute "mkdir -p #{gopath}/src"
            # For example, ln -s ~/builds/peterbourgon/g2g ~/gopath/src/g2g
            shell.execute "ln -s #{home_directory}/builds/#{repository_slug} #{package_path_under_gopath}"
            shell.export_line "GOPATH=#{gopath}"
          end

          def install
            if uses_make?
              # no-op
            else
              "cd #{package_path_under_gopath} && go get -v ."
            end
          end

          def script
            if uses_make?
              "make"
            else
              "go test -v ."
            end
          end

          protected

            def uses_make?
              @uses_make ||= (shell.file_exists?('Makefile'))
            end

            def gopath
              "#{home_directory}/gopath"
            end

            # GOPATH/src/[package] location
            def package_path_under_gopath
              "#{gopath}/src/#{repository_name}"
            end
        end
      end
    end
  end
end
