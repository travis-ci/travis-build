require 'travis/build/appliances/base'
module Travis
  module Build
    module Appliances
      class MavenCentralMirror < Base
        GOOGLE_MAVEN_MIRROR = Travis::Build.config.maven_central_mirror.output_safe
        def apply
          sh.raw bash('travis_maven_central_mirror')
          sh.raw "travis_maven_central_mirror #{GOOGLE_MAVEN_MIRROR}"
        end

        def apply?
          config[:os] != 'windows' && !GOOGLE_MAVEN_MIRROR.to_s.empty?
        end
      end
    end
  end
end
