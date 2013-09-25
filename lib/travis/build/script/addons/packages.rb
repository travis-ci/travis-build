require "shellwords"

module Travis
  module Build
    class Script
      module Addons
        class Packages
          def initialize(script, config)
            @script = script
            @packages = Array(config).map(&:to_s).map(&:shellescape).join(" ")
          end

          def before_install
            @script.if("hash brew 2>/dev/null") do |script|
              script.cmd("brew update", assert: true)
              script.cmd("brew install #{@packages}", assert: true)
            end
            @script.else do |script|
              script.cmd("sudo apt-get -qq update", assert: true)
              script.cmd("sudo apt-get -qq install #{@packages}", assert: true)
            end
          end
        end
      end
    end
  end
end
