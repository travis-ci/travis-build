require 'shellwords'

require 'travis/build/script/shared/directory_cache/base'
require 'travis/build/script/shared/directory_cache/signatures/aws2_signature'

module Travis
  module Build
    class Script
      module DirectoryCache
        class Gcs < Base
          DATA_STORE = :gcs
          SIGNATURE_VERSION = '2'

          WRITE_CURL_HEADER_FILE = true

          def host_proc
            Proc.new do |region|
              'storage.googleapis.com'
            end
          end

          def fetch
            # for AWS V2 compat services, we need to pass authentication
            # information via HTTP headers
            # we accomplish this with the help of a cURL configuration
            # file, which will be written for *each* URL we attempt to fetch
            fetch_urls.each do |url|
              run('GET', url, timing: true)
            end
          end
        end
      end
    end
  end
end
