require 'net/ssh'
require 'net/ssh/shell'

module Travis
  module Build
    class Shell

      # Encapsulates an SSH connection to a remote host.
      class Session
        include Shell::Helpers

        # Remote host environment ssh configuration.
        attr_reader :config

        # The Net::SSH::Session shell
        attr_reader :shell

        # Initialize a shell Session
        #
        # config - A hash containing the timeouts, shell buffer time and ssh connection information
        # block - An optional block of commands to be excuted within the session. If
        #         a block is provided then the session will be started, block evaluated,
        #         and then the session will be closed.
        def initialize(config)
          @config = Hashr.new(config)
          @shell  = nil

          if block_given?
            connect
            yield(self) if block_given?
            close
          end
        end

        # Connects to the remote host.
        #
        # Returns the Net::SSH::Shell
        def connect(silent = false)
          puts "starting ssh session to #{config.host}:#{config.port} ..." unless silent
          options = { :port => config.port, :keys => [config.private_key_path] }
          @shell = Net::SSH.start(config.host, config.username, options).shell
        end

        # Closes the Shell and flushes the buffer
        def close
          shell.wait!
          shell.close!
          buffer.flush
        end

        # Executes a command within the ssh shell, returning true or false depending
        # if the command succeded.
        #
        # command - The command to be executed.
        # options - Optional Hash options (default: {}):
        #           :timeout - The max amount of second to wait before aborting the command.
        #           :echo    - true or false if the command should be echod to the log
        #
        # Returns true if the command completed successfully, false if it failed.
        def execute(command, options = {})
          command = timetrap(command, :timeout => timeout(options)) if options[:timeout]
          command = echoize(command) unless options[:echo] == false

          exec(command) { |p, data| buffer << data } == 0
        end

        # Evaluates a command within the ssh shell, returning the command output.
        #
        # command - The command to be evaluated.
        #
        # Returns the output from the command.
        # Raises RuntimeError if the commands exit status is 1
        def evaluate(command)
          result = ''
          status = exec(command) { |p, data| result << data }
          raise("command #{command} failed: #{result}") unless status == 0
          result
        end

        # Allows you to set a callback when output is received from the ssh shell.
        #
        # block - The block to be called.
        def on_output(&block)
          @on_output = block
        end

        # Checks is the current shell is open.
        #
        # Returns true if the shell has been setup and is open, otherwise false.
        def open?
          shell ? shell.open? : false
        end


        protected

          # Internal: Sets up and returns a buffer to use for the entire ssh session when code
          # is executed.
          def buffer
            @buffer ||= Buffer.new(config.buffer) do |string|
              @on_output.call(string) if @on_output
            end
          end

          # Internal: Executes a command using the SSH Shell.
          #
          # This is where the real SSH shell work is done. The command is run along with
          # callbacks setup for when data is returned. The exit status is also captured
          # when the command has finished running.
          #
          # command - The command to be executed.
          # block   - A block which will be called when output or error output is received
          #           from the shell command.
          #
          # Returns the exit status (0 or 1)
          def exec(command, &on_output)
            status = nil
            shell.execute(command) do |process|
              process.on_output(&on_output)
              process.on_error_output(&on_output)
              process.on_finish { |p| status = p.exit_status }
            end
            shell.session.loop { status.nil? }
            status
          end


        private

          def timeout(options)
            if options[:timeout].is_a?(Numeric)
              options[:timeout]
            else
              timeout = options[:timeout] || :default
              config.timeouts[timeout]
            end
          end
      end
    end
  end
end

