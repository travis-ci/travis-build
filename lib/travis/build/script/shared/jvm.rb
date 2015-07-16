module Travis
  module Build
    class Script
      class Jvm < Script
        include Jdk

        DEFAULTS = {
          jdk: 'default'
        }

        def install
          sh.if '-f gradlew' do
            sh.cmd './gradlew assemble', retry: true, fold: 'install'
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle assemble', retry: true, fold: 'install'
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

