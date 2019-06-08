require 'travis/build/script/node_js/manager'

module Travis
  module Build
    class Script
      class NodeJs < Script
        DEFAULT_VERSION = '0.10'

        YARN_REQUIRED_NODE_VERSION = '4'

        NPM_CI_CMD_VERSION = '5.8.0'

        def export
          super
          if node_js_given_in_config?
            sh.export 'TRAVIS_NODE_VERSION', version, echo: false
          end
        end

        def setup
          super

          setup_os
          convert_legacy_nodejs_config
          version_manager.update unless app_host.empty?
          prepend_path './node_modules/.bin'

          version_manager.install
          sh.newline

          npm_disable_prefix
          npm_disable_spinner
          npm_disable_progress
          npm_disable_strict_ssl unless npm_strict_ssl?
          install_yarn_when_locked
        end

        def announce
          super
          if iojs_3_plus? && !is_win?
            sh.cmd 'echo -e "#include <array>\nstd::array<int, 1> arr = {0}; int main() {return 0;}" > /tmp/foo-$$.cpp', echo: false
            sh.raw "if ! ($CXX -std=c++11 -o /dev/null /tmp/foo-$$.cpp >&/dev/null || g++ -std=c++11 -o /dev/null /tmp/foo-$$.cpp >&/dev/null); then"
            sh.echo "Starting with io.js 3 and Node.js 4, building native extensions requires C++11-compatible compiler, which seems unavailable on this VM. Please read https://docs.travis-ci.com/user/languages/javascript-with-nodejs#Node.js-v4-(or-io.js-v3)-compiler-requirements.", ansi: :yellow
            sh.raw "fi"
            sh.cmd 'rm -f /tmp/foo-$$.cpp', echo: false
          end
          sh.cmd 'node --version'
          sh.cmd 'npm --version'
          version_manager.show_version
          sh.if "-f yarn.lock" do
             sh.cmd 'yarn --version'
             sh.cmd 'hash -d yarn', echo: false
          end
          sh.newline
        end

        def install
          sh.if '-f package.json' do
            sh.if "-f yarn.lock" do
              sh.if yarn_req_not_met do
                npm_install config[:npm_args]
              end
              sh.else do
                sh.cmd "yarn", retry: true, fold: 'install'
              end
            end
            sh.else do
              npm_install config[:npm_args]
            end
          end
        end

        def script
          sh.if '-f package.json' do
            sh.if "-f yarn.lock" do
              sh.if yarn_req_not_met do
                sh.cmd 'npm test'
              end
              sh.else do
                sh.cmd 'yarn test'
              end
            end
            sh.else do
              sh.cmd 'npm test'
            end
          end
          sh.else do
            sh.cmd 'make test'
          end
        end

        def cache_slug
          super << '--node-' << version
        end

        def setup_cache
          if data.cache?(:yarn)
            install_yarn
            sh.fold 'cache.yarn' do
              sh.newline
              directory_cache.add '$(dirname $(yarn cache dir))'
            end
          end
          if data.cache?(:npm)
            sh.fold 'cache.npm' do
              sh.newline
              sh.if packages_locked? do
                directory_cache.add '$HOME/.npm'
              end
              sh.else do
                directory_cache.add 'node_modules'
              end
            end
          end
        end

        def use_directory_cache?
          super || data.cache?(:yarn) || data.cache?(:npm)
        end

        def version
          @version ||= begin
            version = Array(config[:node_js]).first
            version == 0.1 ? '0.10' : version.to_s
          end
        end

        def node_js_given_in_config?
          !!config[:node_js]
        end

        private
          def version_manager
            @version_manager ||= if is_win?
              Travis::Build::NodeJs::Manager.nvs(self)
            else
              Travis::Build::NodeJs::Manager.nvm(self)
            end
          end

          def convert_legacy_nodejs_config
            # TODO deprecate :nodejs
            # some old projects use language: nodejs. MK.
            if config[:nodejs] && !config[:node_js]
              config[:node_js] = config[:nodejs]
            end
          end

          def npm_disable_prefix
            sh.if "$(command -v sw_vers) && -f ${TRAVIS_HOME}/.npmrc" do
              sh.cmd "npm config delete prefix"
            end
          end

          def npm_disable_spinner
            sh.cmd 'npm config set spin false', echo: false, timing: false
          end

          def npm_disable_strict_ssl
            # sh.echo '### Disabling strict SSL ###', ansi: :red
            sh.cmd 'echo "### Disabling strict SSL ###"'
            sh.cmd 'npm conf set strict-ssl false', echo: true
          end

          def npm_disable_progress
            sh.cmd "npm config set progress false", echo: false, timing: false
          end

          def npm_strict_ssl?
            !node_0_6? && !node_0_8? && !node_0_9?
          end

          def node_0_6?
            (config[:node_js] || '').to_s.split('.')[0..1] == %w(0 6)
          end

          def node_0_8?
            (config[:node_js] || '').to_s.split('.')[0..1] == %w(0 8)
          end

          def node_0_9?
            (config[:node_js] || '').to_s.split('.')[0..1] == %w(0 9)
          end

          def iojs_3_plus?
            (config[:node_js] || '').to_s.split('.')[0].to_i >= 3
          end

          def npm_install(args)
            sh.fold "install.npm" do
              sh.if packages_locked? do
                sh.cmd "npm ci #{args}", retry: true
              end
              sh.else do
                sh.cmd "npm install #{args}", retry: true
              end
            end
            sh.newline
          end

          def install_yarn_when_locked
            sh.if "-f yarn.lock" do
              sh.if yarn_req_not_met do
                sh.echo "Node.js version $(node --version) does not meet requirement for yarn." \
                  " Please use Node.js #{YARN_REQUIRED_NODE_VERSION} or later.", ansi: :red
              end
              sh.else do
                install_yarn
              end
            end
          end

          def install_yarn
            sh.if "-z \"$(command -v yarn)\"" do
              sh.fold "install.yarn" do
                sh.if "-z \"$(command -v gpg)\"" do
                  sh.export "YARN_GPG", "no"
                end
                sh.echo   "Installing yarn", ansi: :green
                sh.cmd    "curl -o- -L https://yarnpkg.com/install.sh | bash", echo: true, timing: true
                sh.echo   "Setting up \\$PATH", ansi: :green
                sh.export "PATH", "${TRAVIS_HOME}/.yarn/bin:$PATH"
              end
            end
          end

          def prepend_path(path)
            sh.if "$(echo :$PATH: | grep -v :#{path}:)" do
              sh.export "PATH", "#{path}:$PATH", echo: false
            end
          end

          def yarn_req_not_met
            "$(travis_vers2int $(echo `node --version` | tr -d 'v')) -lt $(travis_vers2int #{YARN_REQUIRED_NODE_VERSION})"
          end

          def is_win?
            config[:os].downcase.strip == 'windows'
          end

          def setup_os
            if is_win?
              sh.fold "#{version_manager.name}.setup" do
                sh.echo "Using NVS for managing Node.js versions on Windows (BETA)", ansi: :yellow
                sh.export 'NVS_HOME', '$ProgramData/nvs', echo: false
                sh.cmd 'git clone --single-branch https://github.com/jasongin/nvs $NVS_HOME'
                sh.cmd 'source $NVS_HOME/nvs.sh'
              end
              sh.newline
            end
          end

          def packages_locked?
            "$(travis_vers2int `npm -v`) -ge $(travis_vers2int #{NPM_CI_CMD_VERSION}) && (-f npm-shrinkwrap.json || -f package-lock.json)"
          end
      end
    end
  end
end
