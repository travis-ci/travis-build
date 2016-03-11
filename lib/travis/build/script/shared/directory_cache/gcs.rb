require 'shellwords'

require 'travis/build/script/shared/directory_cache/base'
require 'travis/build/script/shared/directory_cache/signatures/aws2_signature'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Gcs < Base
          def initialize(sh, data, slug, start = Time.now, data_store = :gcs)
            super
          end

          def host_proc
            Proc.new do |region|
              'storage.googpleapis.com'
            end
          end
        end
      end
    end
  end
end
