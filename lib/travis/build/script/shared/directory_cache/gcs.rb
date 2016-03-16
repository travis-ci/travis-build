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

          def fetch
            # for AWS V2 compat services, we need to pass authentication
            # information via HTTP headers
            # we accomplish this with the help of a cURL configuration
            # file, which will be written for *each* URL we attempt to fetch
            fetch_urls.each do |url|
              signer = signature('GET', URI(url).path, {})
              run('fetch', url, timing: true)
              sh.raw "[ $? -eq 0 ] && cache_found=true"
            end
          end
        end
      end
    end
  end
end
