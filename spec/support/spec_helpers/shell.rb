require 'shellwords'

module SpecHelpers
  module Shell
    def shell_include?(code, string)
      code.include?(string.shellescape)
    end
  end
end
