require 'travis/shell/generator/bash/helpers'

module Travis
  module Shell
    class Generator
      class Bash
        class Cmd
          include Helpers

          attr_reader :code, :options

          def initialize(code, options)
            @code = code
            @options = options
          end

          def to_bash
            cmd = []
            cmd << 'sudo' if options[:sudo]
            cmd << "travis_cmd #{escape(code)}"
            cmd << opts(options) unless opts(options).empty?
            cmd.join(' ')
          end

          private

            def opts(options)
              opts ||= []
              opts << '--assert' if options[:assert]
              opts << '--echo'   if options[:echo]
              opts << "--display #{escape(options[:echo])}" if options[:echo].is_a?(String)
              opts << '--retry'  if options[:retry]
              opts << '--timing' if options[:timing]
              opts.join(' ')
            end
        end
      end
    end
  end
end
