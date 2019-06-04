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
          @directory_cache = cache_class.new(@sh, @data, name, Time.now)
        end

        def use_directory_cache?
          true
        end

        def archive_name
          "#{name}.tgz"
        end
        # for using workspace
        def fetch
          directory_cache.fetch
        end

        def expand
          sh.cmd "tar -xPzf ${CASHER_DIR}/fetch.tgz"
        end

        # for creating workspace
        def compress
          directory_cache.add(*paths)
        end

        def upload
          directory_cache.push
        end

        def install_casher
          directory_cache.install
        end
      end
    end
  end
end
