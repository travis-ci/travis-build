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
          sh.cmd "tar -xPzf ${CASHER_DIR}/#{name}-fetch.tgz"
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
