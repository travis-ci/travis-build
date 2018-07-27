module Travis
  module Build
    class Script
      module Jdk
        def configure
          super
          if uses_jdk?
            if use_install_jdk?(config[:jdk])
              download_install_jdk

              sh.if "-f install-jdk.sh" do
                sh.export "JAVA_HOME", "$HOME/#{jdk}"
                sh.cmd "bash install-jdk.sh #{install_jdk_args config[:jdk]} --target $JAVA_HOME --workspace #{cache_dir}", echo: true, assert: true
                sh.export "PATH", "$JAVA_HOME/bin:$PATH"
                sh.raw 'set +e', echo: false
              end
            else
              sh.if '"$(command -v jdk_switcher &>/dev/null; echo $?)" == 0' do
                sh.cmd "jdk_switcher use #{config[:jdk]}", assert: true, echo: true, timing: false
              end
            end
          end
        end

        def export
          super
          sh.export 'TRAVIS_JDK_VERSION', config[:jdk], echo: false if uses_jdk?
        end

        def setup
          super

          sh.if '-f build.gradle || -f build.gradle.kts' do
            sh.export 'TERM', 'dumb'
          end

          sh.echo "Disabling Gradle daemon", ansi: :yellow
          sh.cmd 'mkdir -p ~/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties', echo: true, timing: false

        end

        def announce
          super
          if uses_java?
            sh.cmd 'java -Xmx32m -version'
            sh.cmd 'javac -J-Xmx32m -version'
          end
        end

        def cache_slug
          return super unless uses_jdk?
          super << '--jdk-' << config[:jdk].to_s
        end

        private

          def uses_java?
            true
          end

          def uses_jdk?
            !!config[:jdk]
          end

          def jdk
            config[:jdk].gsub(/\s/,'')
          end

          def use_install_jdk?(jdk)
            ! install_jdk_args(jdk).empty?
          end

          def download_install_jdk
            return if app_host.empty?
            sh.cmd "curl -sf -O https://#{app_host}/files/install-jdk.sh"
          end

          def install_jdk_args(jdk)
            args_for = {
              # OpenJDK
              'openjdk-ea'   => '-L GPL',
              'openjdk9'     => '-F 9  -L GPL',
              'openjdk10'    => '-F 10 -L GPL',
              'openjdk11'    => '-F 11 -L GPL',
              # OracleJDK
              'oraclejdk-ea' => '-L BCL',
              'oraclejdk10'  => '-F 10 -L BCL',
              'oraclejdk11'  => '-F 11 -L BCL',
            }
            args_for.fetch(jdk, '')
          end

          def cache_dir
            "$HOME/.cache/install-jdk"
          end
      end
    end
  end
end
