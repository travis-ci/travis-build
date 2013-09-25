module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          go: '1.0.3'
        }

        def cache_slug
          super << "--go-" << config[:go].to_s
        end

        def export
          super
          set 'TRAVIS_GO_VERSION', go_version, echo: false
        end

        def announce
          super
          cmd 'gvm version'
          cmd 'go version'
          cmd 'go env', fold: 'go.env'
        end

        def setup
          super
          cmd "gvm get", fold: "gvm.get"
          cmd "gvm update && source #{HOME_DIR}/.gvm/scripts/gvm", fold: "gvm.update"
          cmd "gvm install #{go_version}", fold: "gvm.install"
          cmd "gvm use #{go_version}"
          # Prepend *our* GOPATH entry so that built binaries and packages are
          # easier to find and our `git clone`'d libraries are found by the
          # `go` commands.
          set 'GOPATH', "#{HOME_DIR}/gopath:$GOPATH"
          cmd "mkdir -p #{HOME_DIR}/gopath/src/github.com/#{data.slug.split('/').first}"
          cmd "cp -r $TRAVIS_BUILD_DIR #{HOME_DIR}/gopath/src/github.com/#{data.slug}"
          set "TRAVIS_BUILD_DIR", "#{HOME_DIR}/gopath/src/github.com/#{data.slug}"
          cd "#{HOME_DIR}/gopath/src/github.com/#{data.slug}"
        end

        def install
          uses_make? then: 'true', else: "go get #{config[:gobuild_args]} ./...", fold: 'install', retry: true
        end

        def script
          uses_make? then: 'make', else: "go test #{config[:gobuild_args]} ./..."
        end

        private

          def uses_make?(*args)
            self.if '-f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile', *args
          end

          def go_version
            version = config[:go].to_s
            if version == '1.0'
              'go1.0.3'
            elsif version =~ /^[0-9]\.[0-9\.]+/
              "go#{config[:go]}"
            else
              config[:go]
            end
          end
      end
    end
  end
end
