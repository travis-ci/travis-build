module Travis
  module Build
    class Shell
      class Buffer < String
        attr_reader :callback

        def initialize(&callback)
          @callback = callback
          start
        end

        def flush
          read.tap do |string|
            callback.call(string) if callback
          end if !empty?
        end

        def empty?
          pos == length
        end

        protected

          def pos
            @pos ||= 0
          end

          def read
            string = self[pos, length - pos]
            @pos += string.length
            string
          end

          def start
            @thread = Thread.new do
              loop do
                flush
                sleep(Travis::Worker.config.shell.buffer)
              end
            end
          end
      end
    end
  end
end

