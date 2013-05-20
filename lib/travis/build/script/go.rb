module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {}

        def export
          super
          set 'GOPATH', "#{HOME_DIR}/gopath"
        end

        def setup
          super
          cmd "mkdir -p $GOPATH/src/github.com/#{data.slug.split('/').first}"
          cmd "cp -r $TRAVIS_BUILD_DIR $GOPATH/src/github.com/#{data.slug}"
          set "TRAVIS_BUILD_DIR", "$GOPATH/src/github.com/#{data.slug}"
          cd "$GOPATH"
        end

        def install
          uses_make? then: 'true', else: 'go get -d -v ./... && go build -v ./...', fold: 'install', retry: true
        end

        def script
          uses_make? then: 'make', else: 'go test -v ./...'
        end

        private

          def uses_make?(*args)
            self.if '-f Makefile', *args
          end
      end
    end
  end
end
