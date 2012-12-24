module Travis
  module Build
    class Script
      class Clojure < Script
        include Jdk

        DEFAULTS = {
          lein: 'lein',
          jdk:  'default'
        }

        def export
          super
          export_jdk
        end

        def setup
          super
          setup_jdk
        end

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
