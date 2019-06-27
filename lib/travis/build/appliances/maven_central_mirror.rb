require 'travis/build/appliances/base'
module Travis
  module Build
    module Appliances
      class MavenCentralMirror < Base
        GOOGLE_MAVEN_MIRROR='https://maven-central.storage-download.googleapis.com/repos/central/data/'
        def apply
          sh.raw bash('travis_maven_central_mirror')
          sh.raw "travis_maven_central_mirror #{GOOGLE_MAVEN_MIRROR}"
        end

        def apply?
          config[:os] != 'windows'
        end
      end
    end
  end
end
