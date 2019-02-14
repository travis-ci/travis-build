require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class GitWireProtocol < Base

        GIT_VERSION = /(\d)\.(\d+)\.(\d+)/
        GIT_WIRE_PROTOCOL_MAJOR = 2
        GIT_WIRE_PROTOCOL_MINOR = 18
        def apply
          git_version = `git version`
          major, minor, build = git_version.match(GIT_VERSION).captures
          if major.to_i => GIT_WIRE_PROTOCOL_MAJOR && minor.to_i => GIT_WIRE_PROTOCOL_MINOR
            sh.cmd "git config --global protocol.version 2", assert: false, echo: false
          end
        end
      end
    end
  end
end
