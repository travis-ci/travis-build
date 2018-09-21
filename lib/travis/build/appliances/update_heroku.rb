require 'travis/build/appliances/base'

module Travis
  module Build                                                       
    module Appliances
      class UpdateHeroku < Base
        def apply
          sh.if '"$TRAVIS_DIST" == precise || "$TRAVIS_DIST" == trusty' do
            sh.fold "update_heroku" do
              sh.echo "Updating Heroku", ansi: :yellow
              shell = <<~EOF
              bash -c '
                if which heroku &>/dev/null; then
                  rm -rf /usr/local/heroku
                  apt-get purge -y heroku-toolbelt heroku
                  cd /usr/lib
                  curl -sSL https://cli-assets.heroku.com/heroku-linux-x64.tar.xz | tar Jx
                  ln -sf /usr/lib/heroku/bin/heroku /usr/bin/heroku
                fi
              '
              EOF
              sh.cmd shell, echo: false, sudo: true
              sh.cmd 'heroku version'
            end
          end
        end           
      end
    end               
  end                          
end   
