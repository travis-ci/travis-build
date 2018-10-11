module Travis
  module Build
    class Script
      module Jdk
        def configure
          super
          return unless specifies_jdk?

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

          sh.echo "Disabling Gradle daemon", ansi: :yellow
          sh.cmd 'mkdir -p ~/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties', echo: true
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
      end
    end
  end
end
