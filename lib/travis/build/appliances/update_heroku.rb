require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateHeroku < Base
        def apply
          sh.if '"$TRAVIS_DIST" == trusty && "$(which heroku)" =~ heroku' do
            sh.fold "update_heroku" do
              sh.echo "Updating Heroku", ansi: :yellow
              shell = <<~UPDATE_HEROKU
              bash -c '
                rm -rf /usr/local/heroku
                apt-get purge -y heroku-toolbelt heroku
                cd /usr/lib
                curl -sSL https://cli-assets.heroku.com/heroku-linux-x64.tar.xz | tar Jx
                ln -sf /usr/lib/heroku/bin/heroku /usr/bin/heroku
              '
              UPDATE_HEROKU
              sh.cmd shell, sudo: true, echo: false
              sh.cmd 'heroku version', echo: true
            end
          end
        end
      end
    end
  end
end
