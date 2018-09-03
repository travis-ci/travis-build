module Travis
  module Build
    class Script
      class Elm < NodeJs
        # Default NodeJS version to install
        DEFAULT_NODE_VERSION = '6.10.0'

        DEFAULTS = {
          elm: '0.18.0',
          elm_test: '0.18.12'
        }

        ELM_TEST_REQUIRED_NODE_VERSION = '4.0.0'

        def export
          super
          sh.export 'TRAVIS_ELM_VERSION', elm_version, echo: false
          sh.export 'TRAVIS_ELM_TEST_VERSION', elm_test_version, echo: false
        end

        def configure
          super

          config[:node_js] ||= DEFAULT_NODE_VERSION
        end

        def announce
          super
          sh.cmd 'elm --version', echo: true
          sh.cmd 'elm-test --version', echo: true
        end

        def setup
          super

          sh.echo 'Elm for Travis-CI is not officially supported, ' \
          'but is community maintained.', ansi: :green
          sh.echo 'Please file any issues using the following link',
            ansi: :green
          sh.echo '  https://github.com/travis-ci/travis-ci/issues' \
            '/new?labels=community:elm', ansi: :green
          sh.echo 'and mention \`@avh4\`, \`@lukewestby\`, \`@stoeffel\` and \`@rtfeldman\`' \
            ' in the issue', ansi: :green


          sh.if '! -d sysconfcpus/bin' do
            install_sysconfcpus
          end

          sh.fold 'install.elm' do
            install_elm
            install_elm_test
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

              # In Elm 0.18+, all tests must live in tests/ (whereas previously
              # tests/ was allowed, but so was test/)
              directory_cache.add '$HOME/.cache/elm-tests-stuff', 'tests/elm-stuff'

              # we build sysconfcpus from source, so cache the result
              directory_cache.add '$HOME/.cache/sysconfcpus-cache', 'sysconfcpus'
            end
          end
        end

        def cache_slug
          super << '-elm-' << elm_version
        end

        private

          def elm_version
            config[:elm].to_s
          end

          def elm_version_number(index)
            elm_version.split(".")[index]
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
            config[:elm_test].to_s
          end

          def install_elm
            npm_install '-g elm-use@">=1.1.1 <2.0.0"'
            sh.cmd "elm-use #{elm_version}", retry: true

            convert_binary_to_sysconfcpus 'elm'

            # Beginning with Elm 0.19, there's one `elm` binary and that's it.
            # In that case, there won't be any files to convert here!
            if elm_major_version == 0 && elm_minor_version <= 18
              convert_binary_to_sysconfcpus 'elm-make'
              convert_binary_to_sysconfcpus 'elm-package'
              convert_binary_to_sysconfcpus 'elm-format'
            end
          end

          def install_elm_test
              sh.if "$(vers2int $(echo `node --version` | tr -d 'v')) -lt $(vers2int #{ELM_TEST_REQUIRED_NODE_VERSION})" do
                sh.echo "Node.js version $(node --version) does not meet requirement for elm-test." \
                  " Please use Node.js #{ELM_TEST_REQUIRED_NODE_VERSION} or later.", ansi: :red
              end
              sh.else do
                sh.if "-z \"$(command -v elm-test)\"" do
                  npm_install "-g elm-test@#{elm_test_version}"

                  convert_binary_to_sysconfcpus 'elm-test'
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
