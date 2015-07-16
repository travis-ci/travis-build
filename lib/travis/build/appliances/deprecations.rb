require 'travis/build/appliances/base'

module Travis
  module Build
    module Appliances
      class Deprecations < Base
        def apply
          # script.deprecations.map.with_index do |msg, ix|
          #   sh.fold "deprecated.#{ix}", pos: ix do
          #     sh.deprecate "DEPRECATED: #{msg.gsub /^#{msg[/\A\s*/]}/, ''}"
          #   end
          # end
        end
      end
    end
  end
end
