require 'travis/build/addons/base'
require 'jwt'

module Travis
  module Build
    class Addons
      class Jwt < Base
        SUPER_USER_SAFE = true

        def before_before_install
          sh.echo "JWT addon has been deprecated. Please read our announcement at https://blog.travis-ci.com/2018-01-23-jwt-addon-is-deprecated", ansi: :red
        end
      end
    end
  end
end
