require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class UpdateHeroku < Base
        def apply
          sh.if '("$TRAVIS_DIST" != precise || "$TRAVIS_OS_NAME" == linux) && "$(which heroku)" =~ heroku' do
            update_heroku = <<~UPDATE_HEROKU
            bash -c '
              cd /usr/lib
              (curl -sfSL https://cli-assets.heroku.com/heroku-linux-x64.tar.xz | tar Jx) &&
              ln -sf /usr/lib/heroku/bin/heroku /usr/bin/heroku
            '
            UPDATE_HEROKU

            remove_heroku = <<~REMOVE_HEROKU
            bash -c '
              rm -rf /usr/local/heroku
              apt-get purge -y heroku-toolbelt heroku &>/dev/null
            '
            REMOVE_HEROKU

            sh.cmd update_heroku, sudo: true, echo: false
            sh.if "$? -eq 0" do
              sh.cmd remove_heroku, sudo: true, echo: false
            end
            sh.else do
              sh.echo "Failed to update Heroku CLI", ansi: :red
            end
          end
        end
      end
    end
  end
end
