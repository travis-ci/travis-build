module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          go: '1.3.3'
        }

        def cache_slug
          super << '--go-' << config[:go].to_s
        end

        def export
          super
          sh.export 'TRAVIS_GO_VERSION', go_version, echo: false
        end

        def announce
          super
          sh.cmd 'gvm version'
          sh.cmd 'go version'
          sh.cmd 'go env', fold: 'go.env'
        end

        def setup
          super
          sh.cmd 'gvm get', fold: 'gvm.get'
          sh.cmd "gvm update && source #{HOME_DIR}/.gvm/scripts/gvm", fold: 'gvm.update'
          sh.cmd "gvm install #{go_version} --binary || gvm install #{go_version}", fold: 'gvm.install'
          sh.cmd "gvm use #{go_version}"
          sh.export 'GOPATH', "#{HOME_DIR}/gopath:$GOPATH"
          sh.export 'PATH', "#{HOME_DIR}/gopath/bin:$PATH"
          sh.cmd "mkdir -p #{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}", assert: false, timing: false
          sh.cmd "rsync -az ${TRAVIS_BUILD_DIR}/ #{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}/", assert: false, timing: false
          sh.export "TRAVIS_BUILD_DIR", "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}"
          sh.cd "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}"
        end

        def install
          sh.if '-f Godeps/Godeps.json' do
            sh.set 'GOPATH', '${TRAVIS_BUILD_DIR}/Godeps/_workspace:$GOPATH'
            sh.set 'PATH', '${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:$PATH'

            if go_version >= 'go1.1'
              sh.if '! -d Godeps/_workspace/src' do
                sh.cmd "#{go_get} github.com/tools/godep", echo: true, retry: true, timing: true, assert: true
                sh.cmd 'godep restore', retry: true, timing: true, assert: true, echo: true
              end
            end
          end
          uses_make? then: 'true', else: "#{go_get} #{gobuild_args} ./...", fold: 'install', retry: true
        end

        def script
          uses_make? then: 'make', else: "go test #{gobuild_args} ./..."
        end

        private

          def uses_make?(*args)
            sh.if '-f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile', *args
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
