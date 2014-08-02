require 'travis/build/script/shared/directory_cache/s3'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Dummy
          def initialize(*)
          end

          def method_missing(*)
            self
          end
        end

        def directory_cache
          @directory_cache ||= cache_class.new(data, cache_slug, casher_branch)
        end

        def cache_class
          type = data.cache_options[:type].to_s.capitalize
          type = "Dummy" if type.empty? or !use_directory_cache?
          raise ArgumentError, "unknown caching mode %p" % type unless DirectoryCache.const_defined?(type, false)
          DirectoryCache.const_get(type)
        end

        def use_directory_cache?
          data.cache?(:directories)
        end

        def setup_directory_cache
          directory_cache.fold(self, 'setup build cache') do
            directory_cache.install(self)
            directory_cache.fetch(self)
            Array(data.cache[:directories]).each do |entry|
              directory_cache.add(self, entry)
            end if data.cache? :directories
          end
        end

        def prepare_cache
        end

        def casher_branch
          data.cache?(:edge) ? 'master' : 'production'
        end

        def push_directory_cache
          # only publish cache from pushes to master
          return if data.pull_request
          directory_cache.fold(self, 'store build cache') do
            prepare_cache
            directory_cache.push(self)
          end
        end
      end
    end
  end
end
