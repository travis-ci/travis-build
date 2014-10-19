module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          go: '1.3.3'
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
          cmd "gvm install #{go_version} --binary || gvm install #{go_version}", fold: "gvm.install"
          cmd "gvm use #{go_version}"
          # Prepend *our* GOPATH entry so that built binaries and packages are
          # easier to find and our `git clone`'d libraries are found by the
          # `go` commands.
          set 'GOPATH', "#{HOME_DIR}/gopath:$GOPATH"
          set 'PATH', "$HOME/gopath/bin:$PATH"
          cmd "mkdir -p #{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}", assert: false, timing: false
          cmd "rsync -az ${TRAVIS_BUILD_DIR}/ #{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}/", assert: false, timing: false
          set "TRAVIS_BUILD_DIR", "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}"
          cd "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}"
        end

        def install
          uses_make? then: 'true', else: "#{go_get} #{gobuild_args} ./...", fold: 'install', retry: true
          self.if '-f Godeps/Godeps.json' do |sub|
            sub.cmd "#{go_get} github.com/tools/godep", echo: true, retry: true, timing: true, assert: true
            sub.cmd 'godep restore', retry: true, timing: true, assert: true, echo: true
          end
        end

        def script
          uses_make? then: 'make', else: "go test #{gobuild_args} ./..."
        end

        private

          def uses_make?(*args)
            self.if '-f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile', *args
          end

          def go_version
            version = config[:go].to_s
            case version
            when '1'
              'go1.3.3'
            when '1.0'
              'go1.0.3'
            when '1.2'
              'go1.2.2'
            when '1.3'
              'go1.3.3'
            when /^[0-9]\.[0-9\.]+/
              "go#{config[:go]}"
            else
              config[:go]
            end
          end

          def gobuild_args
            config[:gobuild_args]
          end

          def go_get
            return 'go get' if go_version < 'go1.2'
            'go get -t'
          end
      end
    end
  end
end
