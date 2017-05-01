require 'travis/build/script/shared/jvm'

module Travis
  module Build
    class Script
      class Scala < Jvm

        DEFAULTS = {
          scala: '2.10.4',
          jdk:   'default'
        }

        def export
          super
          sh.export 'TRAVIS_SCALA_VERSION', version, echo: false
        end

        def announce
          super
          sh.echo "Using Scala #{version}"
        end

        def cache_slug
          super << "--scala-" << version
        end
      end
    end
  end
end
