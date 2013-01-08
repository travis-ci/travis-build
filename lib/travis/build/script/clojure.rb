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
          cmd "#{data[:lein]} version"
        end

        def install
          cmd "#{data[:lein]} deps"
        end

        def script
          cmd "#{data[:lein]} test"
        end
      end
    end
  end
end
