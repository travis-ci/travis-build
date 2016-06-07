require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Sonarqube < Base
        SUPER_USER_SAFE = true
        DEFAULT_SQ_HOST_URL = "https://nemo.sonarqube.org"
        SCANNER_CLI_VERSION = "2.6.1"

        def before_before_script
          @scanner_home = "$HOME/.sonarscanner"
          sh.fold 'sonarqube.install' do
            sh.echo "Preparing SonarQube Scanner", echo: false, ansi: :yellow
            install_sonar_scanner

            sh.export 'SONAR_SCANNER_HOME', "#{@scanner_home}/sonar-scanner-#{SCANNER_CLI_VERSION}", echo: true
            sh.export 'SONAR_SCANNER_OPTS', "\"$SONAR_SCANNER_OPTS -Dsonar.host.url=#{DEFAULT_SQ_HOST_URL}\"", echo: true
            set_maven_opts
            sh.export 'GRADLE_OPTS', "\"$GRADLE_OPTS -Dsonar.host.url=#{DEFAULT_SQ_HOST_URL}\"", echo: true
            sh.export 'PATH', "\"$PATH:#{@scanner_home}/sonar-scanner-#{SCANNER_CLI_VERSION}/bin\"", echo: false
          end
        end
        private

        def install_sonar_scanner
          scr = <<SH
  rm -rf #{@scanner_home}
  mkdir -p #{@scanner_home}
  curl -sSLo #{@scanner_home}/sonar-scanner.zip http://repo1.maven.org/maven2/org/sonarsource/scanner/cli/sonar-scanner-cli/#{SCANNER_CLI_VERSION}/sonar-scanner-cli-#{SCANNER_CLI_VERSION}.zip
  unzip #{@scanner_home}/sonar-scanner.zip -d #{@scanner_home}
SH
          sh.raw(scr, echo: false)
        end
        
        # https://github.com/travis-ci/travis-ci/issues/4613
        def set_maven_opts
          scr = <<SH
  echo "export MAVEN_OPTS=\\"\\$MAVEN_OPTS -Dsonar.host.url=#{DEFAULT_SQ_HOST_URL}\\"" >> ~/.mavenrc
SH
          sh.raw(scr, echo: false)
        end
      end
    end
  end
end
