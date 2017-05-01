module Travis
  module Build
    class Script
      class Jvm < Script
        include Jdk

        DEFAULTS = {
          scala: '2.10.4',
          jdk: 'default'
        }

        CLEANUPS = [
          { directory: '$HOME/.ivy2', glob: "ivydata-*.properties"},
          { directory: '$HOME/.sbt',  glob: "*.lock"}
        ]

        SBT_PATH = '/usr/local/bin/sbt'
        SBT_SHA  = '4ad1b8a325f75c1a66f3fd100635da5eb28d9c91'
        SBT_URL  = "https://raw.githubusercontent.com/paulp/sbt-extras/#{SBT_SHA}/sbt"

        def configure
          super
          if use_sbt?
            sh.echo "Updating sbt", ansi: :green

            update_sbt
          end
        end

        def setup
          super
          CLEANUPS.each do |find_arg|
            sh.raw "find #{find_arg[:directory]} -name #{find_arg[:glob]} -delete 2>/dev/null"
          end

          sh.if use_sbt? do
            sh.export 'JVM_OPTS', '@/etc/sbt/jvmopts', echo: true
            sh.export 'SBT_OPTS', '@/etc/sbt/sbtopts', echo: true
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
          sh.elif use_sbt? do
            sh.cmd "sbt#{sbt_args} ++#{version} test"
          end
          sh.else do
            sh.cmd 'ant test'
          end
        end

        private

        def use_sbt?
          '-d project || -f build.sbt'
        end

        def sbt_args
          config[:sbt_args] && " #{config[:sbt_args]}"
        end

        def version
          config[:scala].to_s
        end

        def update_sbt
          if app_host.empty?
            sh.cmd "curl -sf -o sbt.tmp #{SBT_URL}", assert: true
          else
            sh.cmd "curl -sf -o sbt.tmp https://#{app_host}/files/sbt", echo: false
            sh.if "$? -ne 0" do
              sh.cmd "curl -sf -o sbt.tmp #{SBT_URL}", assert: true
            end
          end
          sh.raw "sed -e '/addSbt \\(warn\\|info\\)/d' sbt.tmp | sudo tee #{SBT_PATH} > /dev/null && rm -f sbt.tmp"
        end
      end
    end
  end
end
