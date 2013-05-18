require 'travis/build/script/addons/deploy'

module Travis
  module Build
    class Script
      module Addons
        class AppEngine < Deploy
          GAE_VERSION = '1.8.0'

          private
            def tools
              `curl -o ~/gae.zip "https://googleappengine.googlecode.com/files/google_appengine_#{GAE_VERSION}.zip"`
              `unzip -q -d ~ ~/gae.zip`
            end

            def deploy
              silent do
                `[ $TRAVIS_JAVA_VERSION ] && export gae=~/appengine-java-sdk/bin/appcfg.sh || export gae=~/google-appengine/appcfg.py`
                `echo #{option(:password)} | $gae update --email=#{option(:email)} --passin .`
              end
            end
        end
      end
    end
  end
end
