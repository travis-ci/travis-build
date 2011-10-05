require 'shellwords'

module Travis
  module Build
    class Shell
      module Helpers

        # Formats a shell command to be echod and executed by a ssh session.
        #
        # cmd - command to format.
        #
        # Returns the cmd formatted.
        def echoize(cmd, options = {})
          [cmd].flatten.join("\n").split("\n").map do |cmd|
            "echo #{Shellwords.escape("$ #{cmd.gsub(/timetrap (?:-t \d* )?/, '')}")}\n#{cmd}"
          end.join("\n")
        end

        # Formats a shell command to be run within a timetrap.
        #
        # cmd     - command to format.
        # options - Optional Hash options to be used for configuring the timeout. (default: {})
        #           :timeout - The timeout, in seconds, to be used.
        #
        # Returns the cmd formatted.
        def timetrap(cmd, options = {})
          vars, cmd = parse_cmd(cmd)
          opts = options[:timeout] ? "-t #{options[:timeout]}" : nil
          [vars, 'timetrap', opts, cmd].compact.join(' ')
        end

        # Formats a shell command to be echod and executed by a ssh session.
        #
        # cmd - command to format.
        #
        # Returns the cmd formatted.
        def parse_cmd(cmd)
          cmd.match(/^(\S+=\S+ )*(.*)/).to_a[1..-1].map { |token| token.strip if token }
        end
      end

    end
  end
end

