module Travis
  class Build
    module Job
      class Test
        class Go < Test
          class Config < Hashr
          end

          def setup
            # Here we set up GOPATH + subdirectories structure Go build tool expects,
            # including the assumptions about remote packages.
            # We will just put dependencies here, as source only, via 'go get -d'.
            # The 'go build' step will look for them here, and build them.
            shell.execute "mkdir -p #{gopath}/src/github.com"
            # For example, cp -r ~/builds/peterbourgon/g2g ~/gopath/src/github.com/g2g. go build does not link symlinks.
            shell.execute "cp -r #{home_directory}/builds/#{repository_slug} #{package_path_under_gopath}"
            shell.export_line "GOPATH=#{gopath}"
            # this is not how we do it for all other languages but people experienced with Go suggest
            # this makes sense for Go projects. We still end up in the same directory as with other
            # builders (in the local git repository root) but with `pwd` reporting a path under
            # GOPATH. MK.
            shell.execute "cd #{package_path_under_gopath}"
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

            # GOPATH/src/github.com/[package] location,
            # see travis-build issue #25
            def package_path_under_gopath
              "#{gopath}/src/github.com/#{repository_name}"
            end
        end
      end
    end
  end
end
