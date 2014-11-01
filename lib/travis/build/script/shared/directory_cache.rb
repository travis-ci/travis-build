require 'travis/build/script/shared/directory_cache/noop'
require 'travis/build/script/shared/directory_cache/s3'

module Travis
  module Build
    class Script
      module DirectoryCache
        def directory_cache
          @directory_cache ||= cache_class.new(sh, data, cache_slug)
        end

        def cache_class
          type = data.cache_options[:type].to_s.capitalize
          type = :Noop if type.empty? or !use_directory_cache?
          raise ArgumentError, 'unknown caching mode %p' % type unless DirectoryCache.const_defined?(type, false)
          DirectoryCache.const_get(type)
        end

        def use_directory_cache?
          data.cache?(:directories)
        end

        def setup
          directory_cache.setup
          super
        end

        def finish
          # only publish cache from pushes to master
          return if data.pull_request
          directory_cache.fold(self, 'store build cache') do
            prepare_cache
            directory_cache.push(self)
          end
        end

        def prepare_cache
        end
      end
    end
  end
end
