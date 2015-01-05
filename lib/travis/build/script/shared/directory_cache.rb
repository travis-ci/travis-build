require 'travis/build/script/shared/directory_cache/noop'
require 'travis/build/script/shared/directory_cache/s3'

module Travis
  module Build
    class Script
      module DirectoryCache
        def directory_cache
          @directory_cache ||= begin
            cache = cache_class.new(sh, data, cache_slug)
            cache = Noop.new(sh, data, cache_slug) unless cache.valid? && use_directory_cache?
            cache
          end
        end

        def cache_class
          type = data.cache_options[:type] || :noop
          name = type.to_s.capitalize
          raise ArgumentError, 'unknown caching mode %p' % type unless DirectoryCache.const_defined?(name, false)
          DirectoryCache.const_get(name)
        end

        def use_directory_cache?
          data.cache?(:directories)
        end

        def setup
          directory_cache.setup
          super
        end

        def after_result
          directory_cache.fold('store build cache') do
            prepare_cache
            directory_cache.push
          end
        end

        def prepare_cache
        end
      end
    end
  end
end
