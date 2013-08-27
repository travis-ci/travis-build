module Travis
  module Build
    class Script
      class Jvm < Script
        include Jdk

        DEFAULTS = {
          jdk: 'default'
        }

        def install
          self.if '-f pom.xml', 'mvn install -DskipTests=true -B', fold: 'install', retry: true # Otherwise mvn install will run tests which. Suggestion from Charles Nutter. MK.
        end

        def script
          self.if   '-f gradlew',      './gradlew build'
          self.elif '-f build.gradle', 'gradle build'
          self.elif '-f pom.xml',      'mvn test -B'
          self.else                    'ant test'
        end
      end
    end
  end
end

