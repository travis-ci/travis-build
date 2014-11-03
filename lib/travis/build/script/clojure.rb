require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Clojure < Script
        include Jdk

        DEFAULTS = {
          lein: 'lein',
          jdk:  'default'
        }

        def announce
          super
          sh.cmd "#{lein} version", timing: true
        end

        def install
          sh.cmd "#{lein} deps", fold: 'install', retry: true
        end

        def script
          sh.cmd "#{lein} test"
        end

        def cache_slug
          super << '--lein-' << lein.to_s
        end

        private

          def lein
            config[:lein]
          end
      end
    end
  end
end
