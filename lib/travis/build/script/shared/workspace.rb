require 'travis/build/script/shared/directory_cache'

module Travis
  module Build
    class Script
      class Workspace
        include DirectoryCache
        attr_accessor :sh, :data, :name, :type, :paths
        attr_accessor :directory_cache

        def initialize(sh, data, name, paths, type)
          @sh = sh
          @data = data
          @name = name
          @paths = Array(paths)
          @type = type
          @directory_cache = cache_class.new(@sh, @data, name, Time.now, 'workspace')
          @directory_cache.define_singleton_method :prefixed do |branch, extras, arch|
            parts = case aws_signature_version
            when '2'
              [ 'workspaces', data.build[:id], name ]
            else
              [ data_store_options.fetch(:bucket,''), 'workspaces', data.build[:id], name ]
            end

            "/" << parts.join("/") << '.tgz'
          end
          @directory_cache.define_singleton_method :cache_options do
            data.workspace || data.cache_options || {}
          end
        end

        def use_directory_cache?
          true
        end

        # for using workspace
        def fetch
          directory_cache.fetch
        end

        def expand
          archive = "${CASHER_DIR}/#{name}-fetch.tgz"
          # For any root directories that `tar` would be extracting stuff to,
          # create missing ones and give the user permissions for existing ones.
          # Needed when restoring an archive from another OS with a different filesystem hierarchy.
          sh.raw "tar -tPf \"#{archive}\" | " +
                     # BSD(OSX) xargs doesn't support `-d` so -0 is the only way to handle paths with spaces.
                     # BSD awk doesn't support \0 in variables so have to use printf.
                     # BSD dirname doesn't support multiple arguments; -P 2 reduces time from 30s to 20s on a
                     # sample archive with ~20k entries, further increase doesn't reduce time.
                     "awk '{printf(\"%s%c\",$0,0)}' | " +
                     "xargs -0 $([[ $TRAVIS_OS_NAME =~ (osx|freebsd) ]] && echo '-n 1 -P 2') dirname | " +
                     "sort | uniq | " +
                     # Print only lines that don't have the same prefix as a previous one -- to get only root dirs.
                     # Initial `a` must be an impossible prefix. Since BSD awk doesn't support \0,
                     # \n is acceptable since `tar -t` delimits entries with \n with no option to change that
                     "awk 'index($0,a)!=1{a=$0;printf(\"%s%c\",$0,0)} BEGIN{a=\"\\n\"}' | " +
                     # `install` is more convenient than `mkdir -p` since it can set UID/GID as the same time.
                     # It only sets UID/GID on the leaf entry
                     "xargs -0 echo $([[ $TRAVIS_OS_NAME != 'windows' ]] && echo 'sudo') install -o \"${USER}\" -g \"$(id -g)\" -d"
          sh.cmd "tar -xPf #{archive}"
        end

        # for creating workspace
        def compress
          directory_cache.add(*paths)
        end

        def upload
          directory_cache.push
        end

        def install_casher
          sh.if "-z ${CASHER_DIR}" do
            directory_cache.install
          end
        end
      end
    end
  end
end
