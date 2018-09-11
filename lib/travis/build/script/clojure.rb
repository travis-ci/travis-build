require 'travis/build/script/shared/jdk'

module Travis
  module Build
    class Script
      class Clojure < Script
        include Jdk

        DEFAULTS = {
          lein: 'lein',
          jdk:  'default'
        }

        LEIN_VERSION = '2.6.1'
        VERSION2_AND_UP = /\A[2-9][0-9]*(\.\d+)*\z/

        def configure
          super
          if config[:lein].to_s =~ VERSION2_AND_UP
            update_lein config[:lein].to_s
          end
        end

        def announce
          super
          sh.cmd "#{lein} version"
        end

        def install
          sh.cmd "#{lein} deps", fold: 'install', retry: true
        end

        def script
          sh.cmd "#{lein} test"
        end

        def cache_slug
          super << '--lein-' << lein
        end

        private

          def lein
            if config[:lein] =~ VERSION2_AND_UP
              'lein'
            else
              config[:lein].to_s
            end
          end

          def update_lein(version)
            sh.if "! -f ${TRAVIS_HOME}/.lein/self-installs/home/travis/.lein/leiningen-#{version}-standalone.jar" do
              sh.fold "leiningen.update" do
                sh.echo "Updating leiningen to #{version}", ansi: :yellow
                sh.cmd "env LEIN_ROOT=true curl -L -o /usr/local/bin/lein https://raw.githubusercontent.com/technomancy/leiningen/#{version}/bin/lein", echo: true, assert: true, sudo: true
                sh.cmd "rm -rf ${TRAVIS_HOME}/.lein", echo: false
                sh.cmd "lein self-install", echo: true, assert: true
              end
            end
          end
      end
    end
  end
end
