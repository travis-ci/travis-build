require 'travis/build/appliances/base'
module Travis
  module Build
    module Appliances
      class MavenHttps < Base
        def apply
          sh.raw bash('travis_maven_https')
          sh.raw "travis_maven_https"
        end

        def apply?
          config[:os] != 'windows'
        end
      end
    end
  end
end
