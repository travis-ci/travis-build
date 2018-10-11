require 'uri'

module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          gimme_config: {
            url: Travis::Build.config.gimme.url.output_safe
          },
          go: Travis::Build.config.go_version.output_safe
        }

        def export
          super
          sh.export 'TRAVIS_GO_VERSION', go_version, echo: false
          sh.if '-z $GOMAXPROCS' do
            sh.export 'GOMAXPROCS', '2', echo: false
          end
        end

        def prepare
          super
          ensure_gvm_wiped
          sh.if "! -x ${TRAVIS_HOME}/bin/gimme" do
            update_gimme
          end
        end

        def announce
          super
          sh.cmd 'gimme version'
          sh.cmd 'go version'
          sh.cmd 'go env', fold: 'go.env'
        end

        def setup
          sh.cmd %Q'GIMME_OUTPUT="$(gimme #{go_version} | tee -a ${TRAVIS_HOME}/.bashrc)" && eval "$GIMME_OUTPUT"'

          # NOTE: $GOPATH is a plural ":"-separated var a la $PATH.  We export
          # only a single path here, but users who want to treat $GOPATH as
          # singular *should* probably use "${GOPATH%%:*}" to take the first
          # entry.
          sh.export 'GOPATH', "${TRAVIS_HOME}/gopath", echo: true
          sh.export 'PATH', "${TRAVIS_HOME}/gopath/bin:$PATH", echo: true

          sh.mkdir "${TRAVIS_HOME}/gopath/src/#{go_import_path}", recursive: true, assert: false, timing: false
          # sh.cmd "rsync -az ${TRAVIS_BUILD_DIR}/ ${TRAVIS_HOME}/gopath/src/#{go_import_path}/", assert: false, timing: false
          sh.cmd "tar -czf - ${TRAVIS_BUILD_DIR} | tar -xvf - -C ${TRAVIS_HOME}/gopath/src/#{go_import_path}", assert: false, timing: false

          sh.export "TRAVIS_BUILD_DIR", "${TRAVIS_HOME}/gopath/src/#{go_import_path}"
          sh.cd "${TRAVIS_HOME}/gopath/src/#{go_import_path}", assert: true

          # Defer setting up cache until we have changed directories, so that
          # cache.directories can be properly resolved relative to the directory
          # in which the user-controlled portion of the build starts
          # See https://github.com/travis-ci/travis-ci/issues/3055

          sh.raw '_old_remote="$(git config --get remote.origin.url)"'
          sh.cmd "git config remote.origin.url \"${_old_remote%.git}\"", echo: false
          sh.raw 'unset _old_remote'
          super
        end

        def install
          sh.if uses_15_vendoring? do
            sh.echo 'Using Go 1.5 Vendoring, not checking for Godeps'
          end
          sh.else do
            sh .if '-f Godeps/Godeps.json' do
              sh.export 'GOPATH', '${TRAVIS_BUILD_DIR}/Godeps/_workspace:$GOPATH', retry: false
              sh.export 'PATH', '${TRAVIS_BUILD_DIR}/Godeps/_workspace/bin:$PATH', retry: false

              if go_version != 'go1' && comparable_go_version >= Gem::Version.new('1.1')
                sh.if '! -d Godeps/_workspace/src' do
                  fetch_godep
                  sh.cmd 'godep restore', retry: true, timing: true, assert: true, echo: true
                end
              end
            end
          end

          sh.if uses_make do
            sh.echo 'Makefile detected', retry: true, fold: 'install' # TODO instead negate the condition
          end
          sh.else do
            sh.cmd "#{go_get_cmd} #{gobuild_args} ./...", retry: true, fold: 'install'
          end
        end

        def script
          sh.if uses_make do
            sh.cmd 'make'
          end
          sh.else do
            sh.cmd "go test #{gobuild_args} ./..."
          end
        end

        def cache_slug
          super << '--go-' << go_version
        end

        private

          def uses_make
            '-f GNUmakefile || -f makefile || -f Makefile || -f BSDmakefile'
          end

          # see https://golang.org/doc/go1.6#go_command
          def uses_15_vendoring?
            if (go_version == 'go1' || (go_version != 'tip' && comparable_go_version < Gem::Version.new('1.5')))
              return '2 -eq 5'
            end
            (comparable_go_version < Gem::Version.new('1.6') && go_version != 'tip') ? '$GO15VENDOREXPERIMENT == 1' : '$GO15VENDOREXPERIMENT != 0'
          end

          def gobuild_args
            config[:gobuild_args]
          end

          def go_import_path
            config[:go_import_path] || "#{data.source_host}/#{data.slug}"
          end

          def go_version
            @go_version ||= normalized_go_version
          end

          def normalized_go_version
            v = Array(config[:go]).first.to_s
            return v if v == 'go1'
            v.sub(/^go/, '')
          end

          def comparable_go_version
            if !go_version[/^[0-9]/] # if we don't have a semver version that Gem::Version can read
              return Gem::Version.new('0.0.1') # return a consistent result
            end
            Gem::Version.new(go_version)
          end

          def go_get_cmd
            if go_version == 'go1' ||
              (go_version[/^[0-9]/] &&
                go_version != '1.x' &&
                comparable_go_version < Gem::Version.new('1.2'))
            then
              'go get'
            else
              'go get -t'
            end
          end

          def ensure_gvm_wiped
            sh.cmd 'unset gvm', echo: false
            sh.if "-d ${TRAVIS_HOME}/.gvm" do
              sh.mv "${TRAVIS_HOME}/.gvm", "${TRAVIS_HOME}/.gvm.disabled", echo: false
            end
          end

          def install_gimme
            sh.echo "Installing gimme from #{gimme_url.inspect}", ansi: :yellow
            sh.mkdir "${TRAVIS_HOME}/bin", echo: false, recursive: true
            sh.cmd "curl -sL -o ${TRAVIS_HOME}/bin/gimme '#{gimme_url}'", echo: false
          end

          def gimme_config
            config[:gimme_config]
          end

          def gimme_url
            cleaned = URI.parse(gimme_config[:url]).to_s.output_safe
            return cleaned if cleaned =~ %r{^https://raw\.githubusercontent\.com/travis-ci/gimme}
            DEFAULTS[:gimme_config][:url]
          rescue URI::InvalidURIError => e
            warn e
            DEFAULTS[:gimme_config][:url]
          end

          def update_gimme
            if app_host.empty?
              return install_gimme
            end

            sh.echo "Updating gimme", ansi: :yellow

            sh.mkdir "${TRAVIS_HOME}/bin", echo: false, recursive: true
            sh.cmd "curl -sf -o ${TRAVIS_HOME}/bin/gimme https://#{app_host}/files/gimme", echo: false
            sh.if "$? -ne 0" do
              install_gimme
            end

            sh.cmd "chmod +x ${TRAVIS_HOME}/bin/gimme", echo: false
            sh.export 'PATH', "${TRAVIS_HOME}/bin:$PATH", retry: false, echo: false
            # install bootstrap version so that tip/master/whatever can be used immediately
            sh.cmd %Q'gimme #{DEFAULTS[:go]} &>/dev/null'
          end

          def fetch_godep
            godep = "${TRAVIS_HOME}/gopath/bin/godep"

            sh.mkdir "${TRAVIS_HOME}/gopath/bin", echo: false, recursive: true

            sh.if "$TRAVIS_OS_NAME = osx" do
              sh.cmd "curl -sL -o #{godep} https://#{app_host}/files/godep_darwin_amd64", echo: false
            end
            sh.elif "$TRAVIS_OS_NAME = linux" do
              sh.cmd "curl -sL -o #{godep} https://#{app_host}/files/godep_linux_amd64", echo: false
            end

            sh.if "$? -ne 0" do
              sh.cmd "#{go_get_cmd} github.com/tools/godep", echo: true, retry: true, timing: true, assert: true
            end

            sh.cmd "chmod +x #{godep}"
          end
      end
    end
  end
end
