require_relative 'base'
module Travis
  module Build
    class NodeJs
      class Manager
        class Nvm < Base
          def initialize(node_js)
            super
          end

          def setup

          end

          def update
            nvm_dir = "${TRAVIS_HOME}/.nvm"
            sh.raw "mkdir -p #{nvm_dir}"
            sh.raw "curl -s -o #{nvm_dir}/nvm.sh   https://#{app_host}/files/nvm.sh".output_safe,   assert: false
            sh.raw "curl -s -o #{nvm_dir}/nvm-exec https://#{app_host}/files/nvm-exec".output_safe, assert: false
            sh.raw "chmod 0755 #{nvm_dir}/nvm.sh #{nvm_dir}/nvm-exec", assert: true
            sh.raw "source #{nvm_dir}/nvm.sh", assert: false
          end

          def install
            if node_js_given_in_config?
              use_version node_js.version
            else
              use_default
            end
          end

          def show_version
            sh.cmd 'nvm --version'
          end

          private

          def use_default
            sh.if '-f .nvmrc' do
              sh.echo "Using nodejs version from .nvmrc", ansi: :yellow
              install_version '$(< .nvmrc)'
            end
            sh.else do
              install_version Travis::Build::Script::NodeJs::DEFAULT_VERSION
            end
          end

          def use_version version
            install_version version
          end

          def install_version(ver)
            sh.fold "nvm.install" do
              sh.cmd "nvm install #{ver}", assert: false, timing: true
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
          end

        end
      end
    end
  end
end
