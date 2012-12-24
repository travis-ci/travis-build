module Travis
  module Build
    class Script
      class Jvm < Script
        include Jdk

        DEFAULTS = {
          jdk: 'default'
        }

        def export
          super
          export_jdk
        end

        def setup
          super
          setup_jdk
        end

        def install
          sh_if   '-f build.gradle', 'gradle assemble'
          sh_elif '-f pom.xml',      'mvn install --quiet -DskipTests=true' # Otherwise mvn install will run tests which. Suggestion from Charles Nutter. MK.
        end

        def script
          sh_if   '-f build.gradle', 'gradle check'
          sh_elif '-f pom.xml',      'mvn test'
          sh_else                    'ant test'
        end
      end
    end
  end
end

