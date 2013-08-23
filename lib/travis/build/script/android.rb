module Travis
  module Build
    class Script
      class Android < Script
        include Jdk

        def install
          self.if   '-f build.gradle', 'gradle assemble', fold: 'install', retry: true
          self.elif '-f pom.xml',      'mvn install -DskipTests=true -B', fold: 'install', retry: true # Otherwise mvn install will run tests which. Suggestion from Charles Nutter. MK.
        end

        def script
          self.if   '-f build.gradle', 'gradle check connectedCheck'
          self.elif '-f pom.xml',      'mvn test -B'
        end
      end
    end
  end
end
