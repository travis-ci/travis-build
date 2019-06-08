require 'travis/build/script/shared/directory_cache/base'
require 'travis/build/script/shared/directory_cache/noop'
require 'travis/build/script/shared/directory_cache/gcs'
require 'travis/build/script/shared/directory_cache/s3'

module Travis
  module Build
    class Script
      module DirectoryCache

        def directory_cache
          @directory_cache ||= begin
            cache = cache_class.new(sh, data, cache_slug, Time.now)
            if !cache.valid? || !use_directory_cache?
              cache = Noop.new(sh, data, cache_slug)
            end
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
          if data.cache[:timeout]
            sh.export 'CASHER_TIME_OUT', data.cache[:timeout], echo: false
          end
          data.cache?(:directories)
        end

        def setup_casher
          directory_cache.setup_casher
          super
        end

        def cache
          directory_cache.fold('store build cache') do
            sh.with_errexit_off do
              prepare_cache
            end
            directory_cache.push
          end
          sh.newline
        end

        def prepare_cache
        end
      end
    end
  end
end
