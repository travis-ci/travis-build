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
          cmd "#{config[:lein]} version"
        end

        def install
          cmd "#{config[:lein]} deps"
        end

        def script
          cmd "#{config[:lein]} test"
        end
      end
    end
  end
end
