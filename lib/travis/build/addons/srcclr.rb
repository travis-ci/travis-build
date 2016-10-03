require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Srcclr < Base
        SUPER_USER_SAFE = true

        def before_finish
          sh.if('$TRAVIS_TEST_RESULT = 0') do
            sh.fold 'after_success' do
              sh.cmd "curl -sSL https://download.sourceclear.com/ci.sh | bash", echo: true, timing: true
            end
          end
        end
      end
    end
  end
end
