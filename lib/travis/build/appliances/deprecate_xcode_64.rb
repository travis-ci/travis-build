require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class DeprecateXcode64 < Base
        def apply
          if config[:osx_image] == 'xcode6.4'
            sh.newline
            sh.echo "Running builds with Xcode 6.4 in Travis CI is deprecated and will be removed in January 2019.", ansi: :yellow
            sh.echo "If Xcode 6.4 is critical to your builds, please contact our support team at support@travis-ci.com to discuss options.", ansi: :yellow
          end
        end
      end
    end
  end
end
