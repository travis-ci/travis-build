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
          lfs_skip_smudge: false,
          sparse_checkout: false,
          clone: true
        }
      }

      attr_reader :sh, :data

      def initialize(sh, data)
        @sh = sh
        @data = data
      end

      def checkout
        disable_interactive_auth
        enable_longpaths if config[:os] == 'windows'
        install_ssh_key if install_ssh_key?
        write_netrc if write_netrc?
        sh.newline

        if use_tarball?
          download_tarball
        else
          clone_or_fetch
          submodules
        end
      end

      private

        def disable_interactive_auth
          sh.export 'GIT_ASKPASS', 'echo', :echo => false
        end

        def enable_longpaths
          sh.cmd 'git config --system core.longpaths true', echo: false
        end

        def install_ssh_key?
          data.ssh_key?
        end

        def write_netrc?
          data.installation? && !data.custom_ssh_key? or data.prefer_https?
        end

        def write_netrc
          Netrc.new(sh, data).apply
        end

        def install_ssh_key
          SshKey.new(sh, data).apply
        end

        def download_tarball
          Tarball.new(sh, data).apply
        end

        def clone_or_fetch
          if clone?
            Clone.new(sh, data).apply
          else
            sh.echo 'Skipping \`git clone\` based on given configuration', ansi: :yellow
          end
        end

        def submodules
          Submodules.new(sh, data).apply if submodules?
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

        def clone?
          config[:git][:clone]
        end


        def dir
          data.slug
        end
    end
  end
end
