module Travis
  module Build
    class Script
      class Jvm < Script
        include Jdk

        DEFAULTS = {
          jdk: 'default'
        }

        def install
          self.if   '-f build.gradle', 'gradle assemble', fold: 'install'
          self.elif '-f pom.xml',      'mvn install --quiet -DskipTests=true -B', fold: 'install' # Otherwise mvn install will run tests which. Suggestion from Charles Nutter. MK.
        end

        def script
          self.if   '-f build.gradle', 'gradle check'
          self.elif '-f pom.xml',      'mvn test -B'
          self.else                    'ant test'
        end
      end
    end
  end
end

