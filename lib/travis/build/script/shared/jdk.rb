module Travis
  module Build
    class Script
      module Jdk

        OPENJDK_ALTERNATIVE = {
          'oraclejdk10' => 'openjdk10'
        }

        def configure
          super
          return unless specifies_jdk?

          if jdk_deprecated?
            sh.terminate 2, "#{jdk} is deprecated. See https://www.oracle.com/technetwork/java/javase/eol-135779.html for more details. Consider using #{OPENJDK_ALTERNATIVE[jdk]} instead.", ansi: :red
          end

          jdk = config[:jdk].gsub(/\s/,'')

          return if jdk == 'default'

          vendor, version = jdk_info(jdk)

          sh.echo
          sh.fold 'install_jdk' do
            sh.echo "Installing #{jdk}", ansi: :yellow
            sh.raw("travis_setup_java #{jdk} #{vendor} #{version}", timing: true)
          end
        end

        def export
          super
          sh.export 'TRAVIS_JDK_VERSION', config[:jdk], echo: false if specifies_jdk?
        end

        def setup
          super

          sh.if '-f build.gradle || -f build.gradle.kts' do
            sh.export 'TERM', 'dumb'
          end

          sh.if '"$TRAVIS_DIST" == precise || "$TRAVIS_DIST" == trusty' do
            sh.echo "Disabling Gradle daemon", ansi: :yellow
            sh.cmd 'mkdir -p ~/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties', echo: true, timing: false
          end

          correct_maven_repo
        end

        def announce
          super
          if uses_java?
            sh.cmd 'java -Xmx32m -version'
            sh.cmd 'javac -J-Xmx32m -version'
          end
        end

        def cache_slug
          return super unless specifies_jdk?
          super << '--jdk-' << config[:jdk].to_s
        end

        private

          def uses_java?
            true
          end

          def specifies_jdk?
            !!config[:jdk]
          end

          def jdk_info(jdk)
            m = jdk.match(/(?<vendor>[a-z]+)-?(?<version>.+)?/)
            if m[:vendor]. start_with? 'oracle'
              vendor = 'oracle'
            elsif m[:vendor].start_with? 'openjdk'
              vendor = 'openjdk'
            end
            [ vendor, m[:version] ]
          end

          def cache_dir
            "${TRAVIS_HOME}/.cache/install-jdk"
          end

          def correct_maven_repo
            old_repo = 'https://repository.apache.org/releases/'
            new_repo = 'https://repository.apache.org/content/repositories/releases/'
            sh.cmd "sed -i 's|#{old_repo}|#{new_repo}|g' ~/.m2/settings.xml", echo: false, assert: false, timing: false
          end

          def jdk_deprecated?
            uses_jdk? && OPENJDK_ALTERNATIVE.keys.include?(jdk)
          end
      end
    end
  end
end
