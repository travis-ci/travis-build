require 'erb'

module Travis
  module Build
    class Script
      module Helpers
        def template(filename)
          ERB.new(File.read(File.expand_path(filename, self.class::TEMPLATES_PATH))).result(binding)
        end
      end
    end
  end
end
