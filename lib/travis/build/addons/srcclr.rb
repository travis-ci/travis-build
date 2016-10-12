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
              if api_token.empty?
                sh.if "-z $SRCCLR_API_TOKEN" do
                  sh.echo "SRCCLR_API_TOKEN is empty and api_token is not set in .travis.yml", ansi: :red
                end
                sh.else do
                  sh.echo "Using SRCCLR_API_TOKEN", ansi: :yellow
                end
              else
                sh.if "-n $SRCCLR_API_TOKEN" do
                  sh.echo "SRCCLR_API_TOKEN is set and is used instead of api_token in .travis.yml", ansi: :yellow
                end
                sh.else do
                  sh.echo "Using api_token in .travis.yml", ansi: :yellow
                end
              end

              sh.export 'SRCCLR_API_TOKEN', "${SRCCLR_API_TOKEN:-#{api_token}}", echo: false
              sh.echo "Running SourceClear agent", ansi: :yellow
              debug_env = debug? ? "env DEBUG=1" : ""

              sh.cmd "curl -sSL https://download.sourceclear.com/ci.sh | #{debug_env} bash", echo: true, timing: true
            end
          end
        end

        def debug?
          config[:debug]
        end

        def api_token
          config.fetch(:api_token, '')
        end
      end
    end
  end
end
