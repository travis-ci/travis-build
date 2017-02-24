require 'shellwords'

require 'travis/build/script/shared/directory_cache/base'
require 'travis/build/script/shared/directory_cache/signatures/aws4_signature'

module Travis
  module Build
    class Script
      module DirectoryCache
        class S3 < Base
          def host_proc
            Proc.new do |region|
              case region
              when 'us-east-1'
                's3.amazonaws.com'
              else
                "s3-#{region}.amazonaws.com"
              end
            end
          end
        end
      end
    end
  end
end
