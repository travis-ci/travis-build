require 'digest/md5'
require 'shellwords'
require 'travis/build/addons/base'
require 'travis/build/addons/sonarcloud'

module Travis
  module Build
    class Addons
      class Sonarqube < Sonarcloud
        def after_install
          sh.echo "sonarqube addon has been renamed to sonarcloud. Please update your configuration.", echo: false, ansi: :yellow
        end
      end
    end
  end
end
