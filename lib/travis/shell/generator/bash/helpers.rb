require 'shellwords'
require 'coder'

module Travis
  module Shell
    class Generator
      class Bash
        module Helpers
          ANSI = {
            green: '\033[32;1m',
            red:   '\033[31;1m',
            yellow: '\033[33;1m',
            reset: '\033[0m'
          }

          def ansi(string, keys)
            keys = Array(keys)
            prefix = keys.map { |key| ANSI[key] }.join
            suffix = ANSI[:reset] if keys.any?

            lines = string.split("\n").map do |line|
              line.strip.empty? ? line : [prefix, line, suffix].compact.flatten.join
            end
            lines.join("\n")
          end

          def escape(code)
            Shellwords.escape(Coder.force_encoding(code.to_s))
          end

          # Format as a single argument but allow shell syntax inside
          def doublequote(str)
            '"' + str.gsub('"','\\"') + '"'
          end
        end
      end
    end
  end
end
