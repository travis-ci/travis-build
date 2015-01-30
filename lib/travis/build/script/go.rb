module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          go: '1.4.1'
        }

        def export
          super
          sh.export 'TRAVIS_GO_VERSION', go_version, echo: false
        end

        def prepare
          super
          # TODO: remove this bit once we're shipping gimme via chef (?)
          sh.if "! -x '#{HOME_DIR}/bin/gimme' && ! -x '/usr/local/bin/gimme'" do
            sh.cmd "curl -sLo #{HOME_DIR}/bin/gimme '#{gimme_url}'"
            sh.cmd "chmod +x #{HOME_DIR}/bin/gimme"
            sh.export 'PATH', "#{HOME_DIR}/bin:$PATH", retry: false, echo: false
          end
        end

        def announce
          super
          sh.cmd 'gimme version'
          sh.cmd 'go version'
          sh.cmd 'go env', fold: 'go.env'
        end

        def setup
          super
          sh.cmd "gimme #{go_version} | source /dev/stdin", fold: 'gimme.install'

          sh.export 'GOPATH', "#{HOME_DIR}/gopath:$GOPATH", echo: true
          sh.export 'PATH', "#{HOME_DIR}/gopath/bin:$PATH", echo: true

          sh.mkdir "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}", recursive: true, assert: false, timing: false
          sh.cmd "rsync -az ${TRAVIS_BUILD_DIR}/ #{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}/", assert: false, timing: false

          sh.export "TRAVIS_BUILD_DIR", "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}"
          sh.cd "#{HOME_DIR}/gopath/src/#{data.source_host}/#{data.slug}", assert: true
        end

        def install
          sh.if '-f Godeps/Godeps.json' do
            sh.export 'GOPATH', '${TRAVIS_BUILD_DIR}/Godeps/_workspace:$GOPATH', retry: false
            sh.export 'PATH', '${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:$PATH', retry: false

            if go_version >= '1.1'
              sh.if '! -d Godeps/_workspace/src' do
                sh.cmd "#{go_get_cmd} github.com/tools/godep", echo: true, retry: true, timing: true, assert: true
                sh.cmd 'godep restore', retry: true, timing: true, assert: true, echo: true
              end
            end
          end

          sh.if uses_make do
            sh.cmd 'true', retry: true, fold: 'install' # TODO instead negate the condition
          end
          sh.else do
            sh.cmd "#{go_get_cmd} #{config[:gobuild_args]} ./...", retry: true, fold: 'install'
          end
        end

        def script
          sh.if uses_make do
            sh.cmd 'make'
          end
          sh.else do
            sh.cmd "go test #{config[:gobuild_args]} ./..."
          end
        end

        def cache_slug
          super << '--go-' << go_version
        end

        private

          def uses_make
            '-f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile'
          end

          def gobuild_args
            config[:gobuild_args]
          end

          def go_version
            @go_version ||= normalized_go_version
          end

          def normalized_go_version
            v = config[:go].to_s
            case v
            when '1'
              '1.4.1'
            when '1.0'
              '1.0.3'
            when '1.2'
              '1.2.2'
            when 'go1'
              v
            when /^go/
              v.sub(/^go/, '')
            else
              v
            end
          end

          def go_get_cmd
            go_version < '1.2' ? 'go get' : 'go get -t'
          end

          def gimme_url
            @gimme_url ||= ENV.fetch(
              'TRAVIS_BUILD_GIMME_URL',
              'https://raw.githubusercontent.com/meatballhat/gimme/v0.2.1/gimme'
            )
          end
      end
    end
  end
end
