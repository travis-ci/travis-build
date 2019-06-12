module Travis
  module Build
    class Script
      class Elm < NodeJs
        # Default NodeJS version to install
        DEFAULT_NODE_VERSION = '10.13.0'

        DEFAULTS = {
          elm: 'elm0.19.0',
        }

        ELM_TEST_REQUIRED_NODE_VERSION = '6.0.0'

        def export
          super
          sh.export 'TRAVIS_ELM_VERSION', elm_version, echo: false
          sh.export 'TRAVIS_ELM_TEST_VERSION', elm_test_version, echo: false
          sh.export 'TRAVIS_ELM_FORMAT_VERSION', elm_format_version, echo: false
        end

        def configure
          super

          config[:node_js] ||= DEFAULT_NODE_VERSION
        end

        def announce
          super
          sh.cmd 'elm --version', echo: true
          sh.cmd 'elm-test --version', echo: true

          # elm-format doesn't have --version,
          # but the first line of `elm-format --help` prints the version
          sh.cmd 'elm-format --help | head -n 1', echo: true

          sh.echo '' # A blank line visually separates this from the next cmd
        end

        def setup
          super

          sh.echo 'Elm for Travis-CI is not officially supported, ' \
          'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
            ansi: :green
          sh.echo '  https://travis-ci.community/c/languages/elm', ansi: :green
          sh.echo 'and mention \`@avh4\`, \`@lukewestby\`, \`@stoeffel\` and \`@rtfeldman\`' \
            ' in the issue', ansi: :green

          if using_sysconfcpus?
            sh.if '! -d sysconfcpus/bin' do
              install_sysconfcpus
            end
          end

          sh.fold 'install.elm' do
            sh.echo 'Installing elm, elm-test, and elm-format', ansi: :green
            install_elm
            install_elm_test
            install_elm_format
          end
        end

        def script
          sh.cmd 'elm-format --validate . && elm-test'
        end

        def setup_cache
          if data.cache?(:elm)
            sh.fold 'cache.elm' do
              # Cache the ~/.elm directory.
              directory_cache.add '$HOME/.cache/elm', '$HOME/.elm'

              directory_cache.add '$HOME/.cache/elm-stuff', 'elm-stuff'

              if elm_major_version == 0 && elm_minor_version <= 18
                # In Elm 0.18, some put their tests in ./test instead of ./tests
                directory_cache.add '$HOME/.cache/elm-test-stuff', 'test/elm-stuff'
              end

              if using_sysconfcpus?
                # we build sysconfcpus from source, so cache the result
                directory_cache.add '$HOME/.cache/sysconfcpus-cache', 'sysconfcpus'
              end

              # In Elm 0.18+, all tests live in tests/ by default
              # (whereas previously tests/ was allowed, but so was test/)
              directory_cache.add '$HOME/.cache/elm-tests-stuff', 'tests/elm-stuff'
            end
          end
        end

        def cache_slug
          super << '-elm-' << elm_version
        end

        private

          def elm_version
            Array(config[:elm]).first.to_s
          end

          def elm_version_number(index)
            elm_version.gsub(/[a-zA-Z]/, "").split(".")[index]
          end

          def elm_major_version
            elm_version_number 0
          end

          def elm_minor_version
            elm_version_number 1
          end

          def elm_patch_version
            elm_version_number 2
          end

          def elm_test_version
            (config[:elm_test] || elm_version_tagged).to_s
          end

          def elm_format_version
            (config[:elm_format] || elm_version_tagged).to_s
          end

          def elm_version_tagged
            "elm" + elm_version.sub(/^elm/,"")
          end

          def npm_install_global(package_name, package_version)
            sh.cmd "npm install -g #{package_name}@#{package_version}"
          end

          def using_sysconfcpus?
            # Prior to Elm 0.19, we need sysconfcpus to prevent elm make from
            # thinking it has access to 32 cores. (It actually has access to 2
            # cores in the virtualized environment, but it uses the number of
            # _physical_ cores to determine how many threads to parallelize.)
            @using_sysconfcpus ||= elm_major_version == 0 && elm_minor_version <= 18
          end

          def install_elm
            npm_install_global 'elm', elm_version

            if using_sysconfcpus?
              convert_binary_to_sysconfcpus 'elm-make'
              convert_binary_to_sysconfcpus 'elm-package'
              convert_binary_to_sysconfcpus 'elm'
            end
          end

          def install_elm_format
            npm_install_global 'elm-format', elm_format_version

            if using_sysconfcpus?
              convert_binary_to_sysconfcpus 'elm-format'
            end
          end

          def install_elm_test
              sh.if "$(travis_vers2int $(echo `node --version` | tr -d 'v')) -lt $(travis_vers2int #{ELM_TEST_REQUIRED_NODE_VERSION})" do
                sh.echo "Node.js version $(node --version) does not meet requirement for elm-test." \
                  " Please use Node.js #{ELM_TEST_REQUIRED_NODE_VERSION} or later.", ansi: :red
              end
              sh.else do
                sh.if "-z \"$(command -v elm-test)\"" do
                  npm_install_global 'elm-test', elm_test_version

                  if using_sysconfcpus?
                    convert_binary_to_sysconfcpus 'elm-test'
                  end
                end
              end
          end

          def convert_binary_to_sysconfcpus(binary_name)
            # Wrap the binary in a call to sysconfcpus -n 2
            # to work around https://github.com/travis-ci/travis-ci/issues/6656
            sh.mv "$(npm config get prefix)/bin/#{binary_name}", "$(npm config get prefix)/bin/#{binary_name}-old"

            # Use printf instead of echo here.
            # see https://github.com/rtfeldman/node-elm-compiler/pull/50
            sh.cmd ('printf "#\041/bin/bash\n\necho \"Running ' + binary_name + ' with sysconfcpus -n 2\"\n\n$TRAVIS_BUILD_DIR/sysconfcpus/bin/sysconfcpus -n 2 ' + binary_name + '-old \"\$@\"" > $(npm config get prefix)/bin/' + binary_name)
            sh.chmod '+x', "$(npm config get prefix)/bin/#{binary_name}"
          end

          def install_sysconfcpus
            sh.fold 'sysconfcpus' do
              sh.echo 'Installing sysconfcpus', ansi: :green
              # this is a prerequisite for the convert_binary_to_sysconfcpus method
              # which provides an epic build time improvement - see https://github.com/elm-lang/elm-compiler/issues/1473#issuecomment-245704142
              sh.cmd 'git clone https://github.com/obmarg/libsysconfcpus.git', retry: true
              sh.cd 'libsysconfcpus'
              sh.cmd './configure --prefix=$TRAVIS_BUILD_DIR/sysconfcpus'
              sh.cmd 'make && make install'
              sh.cd '..'
            end
          end
      end
    end
  end
end
