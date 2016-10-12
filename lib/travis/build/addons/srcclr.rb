require 'shellwords'

require 'travis/build/addons/base'

module Travis
  module Build
    class Addons
      class Srcclr < Base
        SUPER_USER_SAFE = true

        def before_finish
          sh.if('$TRAVIS_TEST_RESULT = 0') do
            sh.newline
            sh.fold 'srcclr' do
              sh.if "-z $SRCCLR_API_TOKEN" do
                sh.echo "SRCCLR_API_TOKEN is empty", ansi: :red
              end

              sh.echo "Running SourceClear agent", ansi: :yellow
              debug_env = debug? ? "env DEBUG=1" : ""

              sh.cmd "curl -sSL https://download.sourceclear.com/ci.sh | #{debug_env} bash", echo: true, timing: true
            end
          end
        end

        def debug?
          config[:debug]
        end
      end
    end
  end
end
