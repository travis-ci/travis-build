module Travis
  module Build
    class Script
      class NodeJs < Script
        DEFAULT_VERSION = '0.10'

        NVM_VERSION     = '0.32.0' # to coincide with ../files/nvm.sh version

        def export
          super
          if node_js_given_in_config?
            sh.export 'TRAVIS_NODE_VERSION', version, echo: false
          end
        end

        def setup
          super
          convert_legacy_nodejs_config
          update_nvm
          nvm_install
          npm_disable_prefix
          npm_disable_spinner
          npm_disable_strict_ssl unless npm_strict_ssl?
          setup_npm_cache if use_npm_cache?
        end

        def announce
          super
          if iojs_3_plus?
            sh.cmd 'echo -e "#include <array>\nstd::array<int, 1> arr = {0}; int main() {return 0;}" > /tmp/foo-$$.cpp', echo: false
            sh.raw "if ! ($CXX -std=c++11 -o /dev/null /tmp/foo-$$.cpp >&/dev/null || g++ -std=c++11 -o /dev/null /tmp/foo-$$.cpp >&/dev/null); then"
            sh.echo "Starting with io.js 3 and Node.js 4, building native extensions requires C++11-compatible compiler, which seems unavailable on this VM. Please read https://docs.travis-ci.com/user/languages/javascript-with-nodejs#Node.js-v4-(or-io.js-v3)-compiler-requirements.", ansi: :yellow
            sh.raw "fi"
            sh.cmd 'rm -f /tmp/foo-$$.cpp', echo: false
          end
          sh.cmd 'node --version'
          sh.cmd 'npm --version'
          sh.cmd 'nvm --version'
        end

        def install
          sh.if '-f package.json' do
            sh.cmd "npm install #{config[:npm_args]}", retry: true, fold: 'install'
          end
        end

        def script
          sh.if '-f package.json' do
            sh.cmd 'npm test'
          end
          sh.else do
            sh.cmd 'make test'
          end
        end

        def cache_slug
          super << '--node-' << version
        end

        private

          def convert_legacy_nodejs_config
            # TODO deprecate :nodejs
            # some old projects use language: nodejs. MK.
            if config[:nodejs] && !config[:node_js]
              config[:node_js] = config[:nodejs]
            end
          end

          def node_js_given_in_config?
            !!config[:node_js]
          end

          def version
            @version ||= begin
              version = Array(config[:node_js]).first
              version == 0.1 ? '0.10' : version.to_s
            end
          end

          def nvm_install
            if node_js_given_in_config?
              use_nvm_version
            else
              use_nvm_default
            end
          end

          def use_nvm_default
            sh.if '-f .nvmrc' do
              sh.echo "Using nodejs version from .nvmrc", ansi: :yellow
              install_version '$(< .nvmrc)'
            end
            sh.else do
              install_version DEFAULT_VERSION
            end
          end

          def use_nvm_version
            install_version version
          end

          def install_version(ver)
            sh.cmd "nvm install #{ver}", assert: false
            sh.if '$? -ne 0' do
              sh.echo "Failed to install #{ver}. Remote repository may not be reachable.", ansi: :red
              sh.echo "Using locally available version #{ver}, if applicable."
              sh.cmd "nvm use #{ver}", assert: false, timing: false
              sh.if '$? -ne 0' do
                sh.echo "Unable to use #{ver}", ansi: :red
                sh.cmd "false", assert: true, echo: false, timing: false
              end
            end
            sh.export 'TRAVIS_NODE_VERSION', ver, echo: false
          end

          def update_nvm
            return unless ENV['TRAVIS_BUILD_APP_HOST']
            sh.raw "function vers() {\n  printf \"1%03d%03d%03d%03d\" $(echo \"$1\" | tr '.' ' ')\n}"
            nvm_sh_location = "$HOME/.nvm/nvm.sh"
            sh.if "$(vers `nvm --version`) -lt $(vers #{NVM_VERSION})" do
              sh.echo "Updating nvm to v#{NVM_VERSION}", ansi: :yellow, timing: false
              sh.raw "mkdir -p $HOME/.nvm"
              sh.raw "curl -s -o #{nvm_sh_location} https://#{ENV['TRAVIS_BUILD_APP_HOST']}/files/nvm.sh".untaint, assert: false
              sh.raw "source #{nvm_sh_location}", assert: false
            end
          end

          def npm_disable_prefix
            sh.if "$(command -v sw_vers) && -f $HOME/.npmrc" do
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

          def npm_strict_ssl?
            !node_0_6?
          end

          def node_0_6?
            (config[:node_js] || '').to_s.split('.')[0..1] == %w(0 6)
          end

          def use_npm_cache?
            Array(config[:cache]).include?('npm')
          end

          def setup_npm_cache
            if data.hosts && data.hosts[:npm_cache]
              sh.cmd 'npm config set registry http://registry.npmjs.org/', timing: false
              sh.cmd "npm config set proxy #{data.hosts[:npm_cache]}", timing: false
            end
          end

          def iojs_3_plus?
            (config[:node_js] || '').to_s.split('.')[0].to_i >= 3
          end
      end
    end
  end
end
