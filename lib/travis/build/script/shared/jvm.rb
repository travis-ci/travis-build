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
            sh.cmd './gradlew assemble', echo: true, retry: true, fold: 'install'
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle assemble', echo: true, retry: true, fold: 'install'
          end
          sh.elif '-f pom.xml' do
            sh.cmd 'mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V', echo: true, retry: true, fold: 'install'
          end
        end

        def script
          sh.if '-f gradlew' do
            sh.cmd './gradlew check', echo: true
          end
          sh.elif '-f build.gradle' do
            sh.cmd 'gradle check', echo: true
          end
          sh.elif '-f pom.xml' do
            sh.cmd 'mvn test -B', echo: true
          end
          sh.else do
            sh.cmd 'ant test', echo: true
          end
        end
      end
    end
  end
end

