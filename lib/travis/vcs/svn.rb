require 'travis/vcs/base'
require 'travis/vcs/svn/clone'
require 'travis/vcs/svn/netrc'
require 'travis/vcs/svn/ssh_key'
require 'travis/vcs/svn/submodules'
require 'travis/vcs/svn/tarball'
module Travis
  module Vcs
    class Svn < Base
        DEFAULTS = {
          svn: {
            depth: 50,
            submodules: true,
            strategy: 'clone',
            quiet: false,
            lfs_skip_smudge: false,
            sparse_checkout: false,
            clone: true
          }
        }
      def self.top
        @top ||= Pathname.new(
          `svn info --show-item wc-root 2>/dev/null`.strip
        )
      end

      def self.version
        @version ||= `svn info -r HEAD --show-item last-changed-revision 2>/dev/null`.strip
      end

      def self.paths
        @paths ||= '$(svn status 2>/dev/null | grep ^? | cut -d ' ' -f 8- |tr "\n" ":")'
      end

      def self.clone_cmd(endpoint, source)
        "svn co #{endpoint}/#{source} #{source}"
      end

      def self.checkout_cmd(branch)
        "svn sw ^/branches/#{branch}"
      end

      def self.revision_cmd
        @rev ||= 'svn info -r HEAD --show-item last-changed-revision 2>/dev/null'
      end

      def self.defaults
        DEFAULTS
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
          config_symlink
          clone_or_fetch
          submodules
        end
        delete_netrc if delete_netrc?
      end

      private

        def disable_interactive_auth
          #TODO ?
        end

        def enable_longpaths
          #TODO ?
        end

        def install_ssh_key?
          data.ssh_key?
        end

        def netrc
          @netrc ||= Netrc.new(sh, data)
        end

        def write_netrc?
          data.installation? && !data.custom_ssh_key? or data.prefer_https?
        end

        def write_netrc
          netrc.apply
        end

        def delete_netrc?
          !data.keep_netrc?
        end

        def delete_netrc
          netrc.delete
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
          config[:svn][:submodules]
        end

        def use_tarball?
          config[:svn][:strategy] == 'tarball'
        end

        def clone?
          config[:svn][:clone]
        end

        def config_symlink
          if config[:svn].key? :symlinks
            sh.cmd "git config --global core.symlinks #{!!config[:svn][:symlinks]}", echo: false, assert: false, timing: false
          end
        end

        def dir
          data.slug
        end
    end
  end
end
