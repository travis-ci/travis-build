require 'travis/build/git/clone'
require 'travis/build/git/ssh_key'
require 'travis/build/git/submodules'
require 'travis/build/git/tarball'

module Travis
  module Build
    class Perforce
      # port, host, and user would come from somewhere else
      VARS = {
        P4PORT: 'ssl:eu-perforce.assembla.com:1667',
        P4HOST: 'travisci/VCS',
        P4USER: 'svenfuchs',
        P4CLIENT: 'client'
      }

      attr_reader :sh, :data

      def initialize(sh, data)
        @sh = sh
        @data = data
      end

      def checkout
        install
        export
        login
        sync
      end

      private

        def install
          # this would probably be preinstalled
          sh.fold 'p4.install' do
            sh.cmd 'sudo wget -qO - https://package.perforce.com/perforce.pubkey | sudo apt-key add -'
            sh.cmd 'echo "deb http://package.perforce.com/apt/ubuntu xenial release" | sudo tee /etc/apt/sources.list.d/perforce.list'
            sh.cmd 'sudo apt-get update'
            sh.cmd 'sudo apt-get install helix-p4d'
          end
        end

        def export
          VARS.each do |key, value|
            sh.export key, value, echo: false
          end
        end

        def login
          sh.fold 'p4.login' do
            sh.cmd 'p4 trust -y'
            sh.echo "echo #{password.to_s[0, 2] + '*'.*(30)} | p4 login -a"
            # password would come from somewhere else
            sh.cmd "echo #{password} | p4 login -a", echo: false
          end
        end

        def sync
          sh.fold 'p4.sync' do
            sh.cmd 'p4 client -S //depot/main -o | p4 client -i '
            sh.cmd 'p4 sync -p'
            sh.cmd "cd #{data.slug}"
          end
        end

        def password
          var = env.detect { |var| var.key == 'P4_PASSWORD' }
          var&.value&.untaint
        end

        def env
          Env.new(data).groups.flat_map(&:vars)
        end
    end
  end
end
