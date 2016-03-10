require 'shellwords'

require 'travis/build/script/shared/directory_cache/base'
require 'travis/build/script/shared/directory_cache/signatures/aws4_signature'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3 < Base
        end
      end
    end
  end
end
