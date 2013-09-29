module Travis
  module Build
    class Script
      class Clojure < Script
        include Jdk

        DEFAULTS = {
          lein: 'lein',
          jdk:  'default'
        }

        def cache_slug
          super << "--lein-" << config[:lein].to_s
        end

        def announce
          super
          cmd "#{config[:lein]} version"
        end

        def install
          cmd "#{config[:lein]} deps", fold: 'install', retry: true
        end

        def script
          cmd "#{config[:lein]} test"
        end
      end
    end
  end
end
