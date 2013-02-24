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
          cmd 'mkdir -p $GOPATH/src'
        end

        def install
          uses_make? then: 'true', else: 'go get -d -v ./... && go build -v ./...'
        end

        def script
          uses_make? then: 'make', else: 'go test -v ./...'
        end

        private

          def uses_make?(*args)
            sh_if '-f Makefile', *args
          end
      end
    end
  end
end
