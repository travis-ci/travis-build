module Travis
  module Build
    class Script
      class Jvm < Script
        include Jdk

        DEFAULTS = {
          jdk: 'default'
        }

        def install
          sh.if   '-f gradlew',      './gradlew assemble', fold: 'install', retry: true
          sh.elif '-f build.gradle', 'gradle assemble', fold: 'install', retry: true
          sh.elif '-f pom.xml',      'mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V', fold: 'install', retry: true # Otherwise mvn install will run tests which. Suggestion from Charles Nutter. MK.
        end

        def script
          sh.if   '-f gradlew',      './gradlew check'
          sh.elif '-f build.gradle', 'gradle check'
          sh.elif '-f pom.xml',      'mvn test -B'
          sh.else                    'ant test'
        end
      end
    end
  end
end

