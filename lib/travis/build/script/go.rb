require 'uri'

module Travis
  module Build
    class Script
      class Go < Script
        DEFAULTS = {
          gobuild_args: '-v',
          gimme_config: {
            url: "#{ENV.fetch(
              'TRAVIS_BUILD_GIMME_URL',
              'https://raw.githubusercontent.com/travis-ci/gimme/v1.0.0/gimme'
            )}".untaint,
            force_reinstall: !!ENV['TRAVIS_BUILD_GIMME_FORCE_REINSTALL']
          },
          go: "#{ENV.fetch('TRAVIS_BUILD_GO_VERSION', '1.7.3')}".untaint
        }
        GO_VERSION_ALIASES = {
          '1' => '1.7.3',
          '1.0' => '1.0.3',
          '1.0.x' => '1.0.3',
          '1.1.x' => '1.1.2',
          '1.2' => '1.2.2',
          '1.2.x' => '1.2.2',
          '1.3.x' => '1.3.3',
          '1.4.x' => '1.4.3',
          '1.5.x' => '1.5.4',
          '1.6.x' => '1.6.3',
          '1.7.x' => '1.7.3',
          '1.x' => '1.7.3',
          '1.x.x' => '1.7.3',
          'default' => DEFAULTS[:go]
        }.freeze

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
          sh.if "! -x '#{HOME_DIR}/bin/gimme' && ! -x '/usr/local/bin/gimme'" do
            install_gimme
          end
          install_gimme if gimme_config[:force_reinstall]
        end

        def announce
          super
          sh.cmd 'gimme version'
          sh.cmd 'go version'
          sh.cmd 'go env', fold: 'go.env'
        end

        def setup
          sh.cmd %Q'GIMME_OUTPUT=$(gimme #{go_version}) && eval "$GIMME_OUTPUT"'

          # NOTE: $GOPATH is a plural ":"-separated var a la $PATH.  We export
          # only a single path here, but users who want to treat $GOPATH as
          # singular *should* probably use "${GOPATH%%:*}" to take the first
          # entry.
          sh.export 'GOPATH', "#{HOME_DIR}/gopath", echo: true
          sh.export 'PATH', "#{HOME_DIR}/gopath/bin:$PATH", echo: true

          sh.mkdir "#{HOME_DIR}/gopath/src/#{go_import_path}", recursive: true, assert: false, timing: false
          sh.cmd "rsync -az ${TRAVIS_BUILD_DIR}/ #{HOME_DIR}/gopath/src/#{go_import_path}/", assert: false, timing: false

          sh.export "TRAVIS_BUILD_DIR", "#{HOME_DIR}/gopath/src/#{go_import_path}"
          sh.cd "#{HOME_DIR}/gopath/src/#{go_import_path}", assert: true

          # Defer setting up cache until we have changed directories, so that
          # cache.directories can be properly resolved relative to the directory
          # in which the user-controlled portion of the build starts
          # See https://github.com/travis-ci/travis-ci/issues/3055
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
                  sh.cmd "#{go_get_cmd} github.com/tools/godep", echo: true, retry: true, timing: true, assert: true
                  sh.cmd 'godep restore', retry: true, timing: true, assert: true, echo: true
                end
              end
            end
          end

          sh.if uses_make do
            sh.cmd 'true', retry: true, fold: 'install' # TODO instead negate the condition
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
            v = config[:go].to_s
            return v if v == 'go1'
            GO_VERSION_ALIASES.fetch(v.sub(/^go/, ''), v).sub(/^go/, '')
          end

          def comparable_go_version
            if !go_version[/^[0-9]/] # if we don't have a semver version that Gem::Version can read
              return Gem::Version.new('0.0.1') # return a consistent result
            end
            Gem::Version.new(go_version)
          end

          def go_get_cmd
            if go_version == 'go1' || (go_version !~ /tip|master/ && comparable_go_version <= Gem::Version.new('1.2'))
              'go get'
            else
              'go get -t'
            end
          end

          def ensure_gvm_wiped
            sh.cmd 'unset gvm', echo: false
            sh.if "-d #{HOME_DIR}/.gvm" do
              sh.mv "#{HOME_DIR}/.gvm", "#{HOME_DIR}/.gvm.disabled", echo: false
            end
          end

          def install_gimme
            sh.echo "Installing gimme from #{gimme_url.inspect}", ansi: :yellow
            sh.mkdir "#{HOME_DIR}/bin", echo: false, recursive: true
            sh.cmd "curl -sL -o #{HOME_DIR}/bin/gimme '#{gimme_url}'", echo: false
            sh.cmd "chmod +x #{HOME_DIR}/bin/gimme", echo: false
            sh.export 'PATH', "#{HOME_DIR}/bin:$PATH", retry: false, echo: false
            # install bootstrap version so that tip/master/whatever can be used immediately
            sh.cmd %Q'gimme #{DEFAULTS[:go]} &>/dev/null'
          end

          def gimme_config
            config[:gimme_config]
          end

          def gimme_url
            cleaned = URI.parse(gimme_config[:url]).to_s.untaint
            return cleaned if cleaned =~ %r{^https://raw\.githubusercontent\.com/meatballhat/gimme}
            DEFAULTS[:gimme_config][:url]
          rescue URI::InvalidURIError => e
            warn e
            DEFAULTS[:gimme_config][:url]
          end
      end
    end
  end
end
