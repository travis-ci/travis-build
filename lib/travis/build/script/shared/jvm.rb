module Travis
  module Build
    class Script
      class Jvm < Script
        include Jdk

        DEFAULTS = {
          jdk: 'default'
        }

        CLEANUPS = [
          { directory: '${TRAVIS_HOME}/.ivy2', glob: "ivydata-*.properties"},
          { directory: '${TRAVIS_HOME}/.sbt',  glob: "*.lock"}
        ]

        def setup
          super
          CLEANUPS.each do |find_arg|
            sh.raw "find #{find_arg[:directory]} -name #{find_arg[:glob]} -delete 2>/dev/null"
          end
        end

        def install
          sh.if '-f gradlew' do
            sh.cmd './gradlew assemble', retry: true, fold: 'install'
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle assemble', retry: true, fold: 'install'
          end
          sh.elif '-f mvnw' do
            sh.cmd './mvnw install -DskipTests=true -Dmaven.javadoc.skip=true -B -V', retry: true, fold: 'install'
          end
          sh.elif '-f pom.xml' do
            sh.cmd 'mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V', retry: true, fold: 'install'
          end
        end

        def script
          sh.if '-f gradlew' do
            sh.cmd './gradlew check'
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle check'
          end
          sh.elif '-f mvnw' do
            sh.cmd './mvnw test -B'
          end
          sh.elif '-f pom.xml' do
            sh.cmd 'mvn test -B'
          end
          sh.else do
            sh.cmd 'ant test'
          end
        end
      end
    end
  end
end
