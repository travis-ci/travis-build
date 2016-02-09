require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class AddGithubHostKey < Base
        def apply
          sh.raw %(ssh-keyscan -t rsa,dsa -H github.com 2>&1 | tee -a #{Travis::Build::HOME_DIR}/.ssh/known_hosts), echo: false
        end
      end
    end
  end
end
