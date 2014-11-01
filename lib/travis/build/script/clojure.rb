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
          sh.cmd "#{config[:lein]} version"
        end

        def install
          sh.cmd "#{config[:lein]} deps", fold: 'install', retry: true
        end

        def script
          sh.cmd "#{config[:lein]} test"
        end

        def cache_slug
          super << '--lein-' << config[:lein].to_s
        end
      end
    end
  end
end
