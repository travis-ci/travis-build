module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          go: '1.3'
        }

        def cache_slug
          super << "--go-" << config[:go].to_s
        end

        def export
          super
          set 'TRAVIS_GO_VERSION', go_version
        end

        def announce
          super
          cmd 'gvm version', echo: true, timing: false
          cmd 'go version', echo: true, timing: false
          cmd 'go env', echo: true, timing: false, fold: 'go.env'
        end

        def setup
          super
          cmd 'gvm get', echo: true, fold: 'gvm.get'
          cmd "gvm update && source #{HOME_DIR}/.gvm/scripts/gvm", echo: true, fold: "gvm.update"
          cmd "gvm install #{go_version} --binary || gvm install #{go_version}", echo: true, fold: "gvm.install"
          cmd "gvm use #{go_version}", echo: true
          # Prepend *our* GOPATH entry so that built binaries and packages are
          # easier to find and our `git clone`'d libraries are found by the
          # `go` commands.
          set 'GOPATH', "#{HOME_DIR}/gopath:$GOPATH"
          cmd "mkdir -p #{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug.split('/').first}", assert: false, timing: false
          cmd "cp -r $TRAVIS_BUILD_DIR #{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}", echo: true, assert: false, timing: false
          set "TRAVIS_BUILD_DIR", "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}"
          cd "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}"
        end

        def install
          sh.if uses_make do |sh|
            cmd 'true'
          end
          sh.else do
            cmd "go get #{config[:gobuild_args]} ./...", echo: true, retry: true, fold: 'install'
          end
        end

        def script
          sh.if uses_make do |sh|
            cmd 'make', echo: true
          end
          sh.else do
            cmd "go test #{config[:gobuild_args]} ./...", echo: true
          end
        end

        private

          def uses_make
            '-f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile'
          end

          def go_version
            version = config[:go].to_s
            case version
            when '1'
              'go1.3'
            when '1.0'
              'go1.0.3'
            when '1.2'
              'go1.2.2'
            when /^[0-9]\.[0-9\.]+/
              "go#{config[:go]}"
            else
              config[:go]
            end
          end
      end
    end
  end
end
