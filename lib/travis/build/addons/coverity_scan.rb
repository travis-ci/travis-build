module Travis
  module Build
    class Addons
      class CoverityScan
        SUPER_USER_SAFE = true

        SCAN_URL      = 'https://scan.coverity.com'

        attr_reader :script, :sh, :data, :config

        def after_configure
          sh.raw "echo -n | openssl s_client -connect scan.coverity.com:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | sudo tee -a /etc/ssl/certs/ca-certificates.crt >/dev/null"
        end

        def initialize(script, sh, data, config)
          @script = script
          @sh = sh
          @data = data
          @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          @config[:build_script_url] ||= "#{SCAN_URL}/scripts/travisci_build_coverity_scan.sh"
        end

        # This method consumes the script method of the caller, calling it or the Coverity Scan
        #   script depending on the TRAVIS_BRANCH env variable.
        # The Coverity Scan build therefore overrides the default script, but only on the
        #   coverity_scan branch.
        def script
          sh.raw "echo -en 'coverity_scan:start\\r'"
          sh.if "${COVERITY_VERBOSE} = 1", echo: true do
            sh.raw "set -x"
          end
          sh.set 'PROJECT_NAME', @config[:project][:name], echo: true
          set_coverity_scan_branch
          sh.if "${COVERITY_SCAN_BRANCH} = 1", echo: true do
              sh.raw "echo -e \"\033[33;1mCoverity Scan analysis selected for branch \"$TRAVIS_BRANCH\".\033[0m\""
            authorize_quota
            build_command
          end
          sh.raw "echo -en 'coverity_scan:end\\r'"
        end

        private

        def authorize_quota
          scr = <<SH
export SCAN_URL=#{SCAN_URL}
AUTH_RES=`curl -s --form project="$PROJECT_NAME" --form token="$COVERITY_SCAN_TOKEN" $SCAN_URL/api/upload_permitted`
if [ "$AUTH_RES" = "Access denied" ]; then
  echo -e "\033[33;1mCoverity Scan API access denied. Check \\$PROJECT_NAME and \\$COVERITY_SCAN_TOKEN.\033[0m"
  exit 1
else
  AUTH=`echo $AUTH_RES | ruby -e "require 'rubygems'; require 'json'; puts JSON[STDIN.read]['upload_permitted']"`
  if [ "$AUTH" = "true" ]; then
    echo -e "\033[33;1mCoverity Scan analysis authorized per quota.\033[0m"
  else
    WHEN=`echo $AUTH_RES | ruby -e "require 'rubygems'; require 'json'; puts JSON[STDIN.read]['next_upload_permitted_at']"`
    echo -e "\033[33;1mCoverity Scan analysis NOT authorized until $WHEN.\033[0m"
    exit 0
  fi
fi
SH
          sh.raw(scr, echo: true)
        end

        def set_coverity_scan_branch
          scr = <<SH
export COVERITY_SCAN_BRANCH=`ruby -e "puts '$TRAVIS_BRANCH' =~ /\\A#{@config[:branch_pattern]}\\z/ ? 1 : 0"`
SH
          sh.raw(scr, echo: true)
        end

        def build_command
          sh.raw "export TRAVIS_TEST_RESULT=$(( ${TRAVIS_TEST_RESULT:-0} ))"
          sh.if "${TRAVIS_TEST_RESULT} = 0", echo: true do
            sh.fold('build_coverity') do
              env = []
              env << "COVERITY_SCAN_PROJECT_NAME=\"$PROJECT_NAME\""
              env << "COVERITY_SCAN_NOTIFICATION_EMAIL=\"${COVERITY_SCAN_NOTIFICATION_EMAIL:-#{@config[:notification_email]}}\""
              env << "COVERITY_SCAN_BUILD_COMMAND=\"${COVERITY_SCAN_BUILD_COMMAND:-#{@config[:build_command]}}\""
              env << "COVERITY_SCAN_BUILD_COMMAND_PREPEND=\"${COVERITY_SCAN_BUILD_COMMAND_PREPEND:-#{@config[:build_command_prepend]}}\""
              env << "COVERITY_SCAN_BRANCH_PATTERN=${COVERITY_SCAN_BRANCH_PATTERN:-#{@config[:branch_pattern]}}"
              sh.cmd "curl -s #{@config[:build_script_url]} | #{env.join(' ')} bash", echo: true
            end
          end
          sh.else echo:true do
            sh.raw "echo -e \"\033[33;1mSkipping build_coverity due to previous error\033[0m\""
          end
        end

      end
    end
  end
end
