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
          super << "--lein-" << lein.to_s
        end

        def announce
          super
          sh.cmd "#{lein} version", echo: true, timing: false
        end

        def install
          sh.cmd "#{lein} deps", fold: 'install', echo: true, retry: true
        end

        def script
          sh.cmd "#{lein} test", echo: true
        end

        def lein
          config[:lein]
        end
      end
    end
  end
end
