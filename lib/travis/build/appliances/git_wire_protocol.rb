require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class GitWireProtocol < Base
        def apply
          write_git_config = <<~WRITE_GIT_CFG
          if git --version | ruby -lane 'exit(Gem::Version.new($F[-1]) > Gem::Version.new("2.1.17"))'; then
            git config --global protocol.version 2
          fi >/dev/null 2>&1
          WRITE_GIT_CFG
          sh.raw(write_git_config, echo: false, assert: false)
        end
      end
    end
  end
end

