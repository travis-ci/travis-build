module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          go: 'go1.0.3'
        }

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
          cmd "gvm install #{go_version} || true", fold: "gvm.install"
          cmd "gvm use #{go_version}"
          set 'GOPATH', "#{HOME_DIR}/gopath:$GOPATH"
          cmd "mkdir -p #{HOME_DIR}/gopath/src/github.com/#{data.slug.split('/').first}"
          cmd "cp -r $TRAVIS_BUILD_DIR #{HOME_DIR}/gopath/src/github.com/#{data.slug}"
          set "TRAVIS_BUILD_DIR", "#{HOME_DIR}/gopath/src/github.com/#{data.slug}"
          cd "#{HOME_DIR}/gopath/src/github.com/#{data.slug}"
        end

        def install
          uses_make? then: 'true', else: 'go get -d -v ./... && go build -v ./...', fold: 'install', retry: true
        end

        def script
          uses_make? then: 'make', else: 'go test -v ./...'
        end

        private

          def uses_make?(*args)
            self.if '-f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile', *args
          end

          def go_version
            config[:go].to_s
          end
      end
    end
  end
end
