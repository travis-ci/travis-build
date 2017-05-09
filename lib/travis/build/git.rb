require 'travis/build/git/clone'
require 'travis/build/git/ssh_key'
require 'travis/build/git/submodules'
require 'travis/build/git/tarball'

module Travis
  module Build
    class Git
      DEFAULTS = {
        git: {
          depth: 50,
          submodules: true,
          strategy: 'clone',
          quiet: false,
          lfs_skip_smudge: false
        }
      }

      attr_reader :sh, :data

      def initialize(sh, data)
        @sh = sh
        @data = data
      end

      def checkout
        disable_interactive_auth
        install_ssh_key

        if use_tarball?
          download_tarball
        else
          clone_or_fetch
          submodules
        end

        rm_key
      end

      private

        def disable_interactive_auth
          sh.export 'GIT_ASKPASS', 'echo', :echo => false
        end

        def install_ssh_key
          SshKey.new(sh, data).apply if data.ssh_key
        end

        def download_tarball
          Tarball.new(sh, data).apply
        end

        def clone_or_fetch
          Clone.new(sh, data).apply
        end

        def submodules
          Submodules.new(sh, data).apply if submodules?
        end

        def rm_key
          sh.rm '~/.ssh/source_rsa', force: true, echo: false
        end

        def config
          DEFAULTS.merge(data.config)
        end

        def submodules?
          config[:git][:submodules]
        end

        def use_tarball?
          config[:git][:strategy] == 'tarball'
        end

        def dir
          data.slug
        end
    end
  end
end
