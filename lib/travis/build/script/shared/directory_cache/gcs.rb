require 'shellwords'

require 'travis/build/script/shared/directory_cache/base'
require 'travis/build/script/shared/directory_cache/signatures/aws2_signature'

require 'uri'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Gcs < Base
          def host_proc
            Proc.new do |region|
              'storage.googleapis.com'
            end
          end
        end
      end
    end
  end
end
