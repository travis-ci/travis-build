module Travis
  module Build
    class Script
      module Addons
        class Deploy
          attr_accessor :script, :config

          def initialize(script, config)
            @script = script
            @config = config.respond_to?(:to_hash) ? config.to_hash : {}
          end

          def after_success
            export.each do |key, value|
              script.set(key, value, echo: false, assert: false) if value
            end

            fold("Installing tools for %s deploy") { tools } if respond_to?(:tools, true)
            fold("Deploying to %s") { deploy }

            Array(config[:run]).each do |cmd|
              fold { run(cmd) }
            end
          end

          private
            def export
              {}
            end

            def fold(message = nil)
              @fold_count ||= 0
              @fold_count  += 1
              script.fold("#{fold_name}.#{@fold_count}") do
                say(message % service_name, 33) if message
                yield
              end
            end

            def fold_name
              service_name.split(" ").map(&:downcase).join("_")
            end

            def service_name
              self.class.name[/[^:]+$/].split(/(?=[A-Z])/).join(" ")
            end

            def run(cmd)
              die("Don't know how to execute custom commands on #{service_name}, send help!")
            end

            def die(message)
              say(message, 31)
              # call non-existing function, name recommended by josh
              script.cmd('hslghslhg', assert: true, echo: false)
            end

            def app
              config[:app] || '$(basename $(pwd))'
            end

            def say(message, color = nil)
              return say('\033[%d;1m%s\033[0m' % [color, message]) if color
              script.cmd("echo -e \"#{message}\"", assert: false, echo: false)
            end

            def `(cmd)
              script.cmd(cmd, assert: true, echo: true)
            end
        end
      end
    end
  end
end
